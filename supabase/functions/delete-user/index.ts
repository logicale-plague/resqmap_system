// Fallback typing for editors that are not using the Deno language service.
declare const Deno: {
  serve: (handler: (req: Request) => Response | Promise<Response>) => void;
  env: {
    get: (key: string) => string | undefined;
  };
};

// @ts-ignore URL imports are resolved by the Supabase Edge (Deno) runtime.
import { createClient } from '@supabase/supabase-js';

const jsonHeaders = {
  'Content-Type': 'application/json',
};

type DeleteUserRequest = {
  userId?: unknown;
};

function jsonResponse(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  });
}

function parseAndValidateUserId(body: DeleteUserRequest): string {
  if (typeof body.userId !== 'string') {
    throw new Error('Invalid payload: userId must be a string.');
  }

  const userId = body.userId.trim();
  if (userId.length === 0) {
    throw new Error('Invalid payload: userId is required.');
  }

  // Supabase auth user IDs are UUIDs; validate format to reject malformed input.
  const uuidPattern =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (!uuidPattern.test(userId)) {
    throw new Error('Invalid payload: userId must be a valid UUID.');
  }

  return userId;
}

async function verifyAndAuthorizeRequest(
  req: Request,
  supabaseUrl: string,
  serviceRoleKey: string,
  targetUserId: string
): Promise<{ isAuthorized: boolean; error?: string }> {
  const authHeader = req.headers.get('authorization');
  if (authHeader == null || typeof authHeader !== 'string') {
    return { isAuthorized: false, error: 'Missing authorization header.' };
  }

  const token = authHeader.replace(/^Bearer\s+/i, '');
  if (token.length === 0) {
    return { isAuthorized: false, error: 'Invalid bearer token format.' };
  }

  try {
    const authClient = createClient(supabaseUrl, serviceRoleKey);
    const { data: user, error } = await authClient.auth.getUser(token);

    if (error != null || user?.user?.id == null) {
      return { isAuthorized: false, error: 'Invalid or expired token.' };
    }

    const callerId = user.user.id;

    // Authorization: caller must be the same user or have admin role.
    const isOwnDecision = callerId === targetUserId;
    const isAdmin =
      user.user.user_metadata?.role === 'admin' ||
      user.user.app_metadata?.role === 'admin';

    if (!isOwnDecision && !isAdmin) {
      return {
        isAuthorized: false,
        error: 'Not authorized to delete this user.',
      };
    }

    return { isAuthorized: true };
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Token verification failed.';
    return { isAuthorized: false, error: message };
  }
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return jsonResponse(405, {
      error: 'Method not allowed. Use POST.',
    });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (supabaseUrl == null || serviceRoleKey == null) {
      return jsonResponse(500, {
        error: 'Missing server configuration for Supabase Admin API.',
      });
    }

    let requestBody: DeleteUserRequest;
    try {
      requestBody = (await req.json()) as DeleteUserRequest;
    } catch (_) {
      return jsonResponse(400, {
        error: 'Invalid JSON body.',
      });
    }

    let userId: string;
    try {
      userId = parseAndValidateUserId(requestBody);
    } catch (e) {
        console.error('User ID validation error:', e);
      return jsonResponse(400, {
        error: 'Unexpected server error during payload validation.',
      });
    }

    const authResult = await verifyAndAuthorizeRequest(
      req,
      supabaseUrl,
      serviceRoleKey,
      userId
    );

    if (!authResult.isAuthorized) {
      const statusCode = authResult.error?.includes('authorization')
        ? 403
        : 401;
      return jsonResponse(statusCode, {
        error: authResult.error ?? 'Authorization failed.',
      });
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const { error } = await adminClient.auth.admin.deleteUser(userId);

    if (error != null) {
      const status = error.status ?? 400;
      return jsonResponse(status, {
        error: error.message,
      });
    }

    return jsonResponse(200, {
      success: true,
      userId,
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Unexpected server error.';
    return jsonResponse(500, {
      error: message,
    });
  }
});

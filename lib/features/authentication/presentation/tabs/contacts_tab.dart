import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({
    super.key,
    this.userPostalCode,
    this.localDRRMByPostalCode = const <String, String>{},
  });

  final String? userPostalCode;
  final Map<String, String> localDRRMByPostalCode;

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final List<_PersonalContact> _personalContacts = <_PersonalContact>[];

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();

    return Material(
      color: Colors.transparent,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _SectionWidget(
                  section: sections[index],
                  onAddPersonalContact: _showAddPersonalContactDialog,
                  onEditPersonalContact: _showEditPersonalContactDialog,
                  onDeletePersonalContact: _deletePersonalContact,
                ),
                childCount: sections.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_ContactSection> _buildSections() {
    final localDRRMPhone = _lookupLocalDRRMPhone(
      userPostalCode: widget.userPostalCode,
      directory: widget.localDRRMByPostalCode,
    );

    return <_ContactSection>[
      _ContactSection(
        title: 'Emergency Hotlines',
        contacts: [
          _ContactItem(
            icon: Icons.local_police,
            name: '911 (National Emergency Hotline)',
            phone: '911',
          ),
          _ContactItem(
            icon: Icons.account_balance,
            name: 'Local DRRM Office',
            phone: localDRRMPhone ?? 'N/A',
          ),
          const _ContactItem(
            icon: Icons.local_police,
            name: 'Police Station',
            phone: 'N/A',
          ),
          const _ContactItem(
            icon: Icons.local_fire_department,
            name: 'Fire Department',
            phone: 'N/A',
          ),
          const _ContactItem(
            icon: Icons.emergency,
            name: 'Ambulance',
            phone: 'N/A',
          ),
        ],
      ),
      const _ContactSection(
        title: 'Medical & Health Services',
        contacts: [
          _ContactItem(
            icon: Icons.local_hospital,
            name: 'Nearest Hospitals',
            phone: 'N/A',
          ),
          _ContactItem(
            icon: Icons.medical_services,
            name: 'Health Centers / Clinics',
            phone: 'N/A',
          ),
          _ContactItem(
            icon: Icons.volunteer_activism,
            name: 'Red Cross',
            phone: 'N/A',
          ),
        ],
      ),
      const _ContactSection(
        title: 'Disaster Agencies',
        contacts: [
          _ContactItem(icon: Icons.security, name: 'NDRRMC', phone: 'N/A'),
          _ContactItem(icon: Icons.cloud, name: 'PAGASA', phone: 'N/A'),
          _ContactItem(icon: Icons.public, name: 'PHIVOLCS', phone: 'N/A'),
          _ContactItem(
            icon: Icons.directions_boat,
            name: 'Coast Guard',
            phone: 'N/A',
          ),
        ],
      ),
      const _ContactSection(
        title: 'Local Government Units',
        contacts: [
          _ContactItem(
            icon: Icons.location_city,
            name: 'Barangay Hall',
            phone: 'N/A',
          ),
          _ContactItem(
            icon: Icons.groups,
            name: 'Barangay Officials',
            phone: 'N/A',
          ),
          _ContactItem(
            icon: Icons.apartment,
            name: 'City/Municipal Hall',
            phone: 'N/A',
          ),
        ],
      ),
      const _ContactSection(
        title: 'Utilities',
        contacts: [
          _ContactItem(
            icon: Icons.electric_bolt,
            name: 'Electric Company',
            phone: 'N/A',
          ),
          _ContactItem(
            icon: Icons.water_drop,
            name: 'Water District',
            phone: 'N/A',
          ),
          _ContactItem(
            icon: Icons.cell_tower,
            name: 'Telecom Providers',
            phone: 'N/A',
          ),
        ],
      ),
      _ContactSection(
        title: 'Personal Emergency Contacts',
        contacts: _personalContacts
            .map(
              (p) => _ContactItem(
                icon: Icons.person,
                name: p.name,
                phone: p.phone,
                personalId: p.id,
              ),
            )
            .toList(growable: false),
        isPersonal: true,
      ),
    ];
  }

  String? _lookupLocalDRRMPhone({
    required String? userPostalCode,
    required Map<String, String> directory,
  }) {
    final postal = userPostalCode?.trim();
    if (postal == null || postal.isEmpty) return null;
    final phone = directory[postal];
    if (phone == null || phone.trim().isEmpty) return null;
    return phone.trim();
  }

  Future<void> _showAddPersonalContactDialog() async {
    final result = await showDialog<_PersonalContact?>(
      context: context,
      builder: (_) {
        return const _PersonalContactDialog(
          title: 'Add Contact',
          confirmLabel: 'Add',
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      _personalContacts.add(result);
    });
  }

  Future<void> _showEditPersonalContactDialog(String personalId) async {
    final idx = _personalContacts.indexWhere((c) => c.id == personalId);
    if (idx < 0) return;

    final existing = _personalContacts[idx];

    final edited = await showDialog<_PersonalContact?>(
      context: context,
      builder: (_) {
        return _PersonalContactDialog(
          title: 'Edit Contact',
          confirmLabel: 'Save',
          existingId: existing.id,
          initialName: existing.name,
          initialPhone: existing.phone,
        );
      },
    );

    if (!mounted || edited == null) return;

    setState(() {
      _personalContacts[idx] = edited;
    });
  }

  void _deletePersonalContact(String personalId) {
    setState(() {
      _personalContacts.removeWhere((c) => c.id == personalId);
    });
  }
}

class _SectionWidget extends StatelessWidget {
  const _SectionWidget({
    required this.section,
    required this.onAddPersonalContact,
    required this.onEditPersonalContact,
    required this.onDeletePersonalContact,
  });

  final _ContactSection section;
  final VoidCallback onAddPersonalContact;
  final void Function(String personalId) onEditPersonalContact;
  final void Function(String personalId) onDeletePersonalContact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              if (section.isPersonal)
                TextButton.icon(
                  onPressed: onAddPersonalContact,
                  icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
                  label: Text(
                    'Add',
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (section.isPersonal && section.contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No personal contacts yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ...section.contacts.map(
            (c) => _ContactCard(
              item: c,
              onEditPersonal: section.isPersonal && c.personalId != null
                  ? () => onEditPersonalContact(c.personalId!)
                  : null,
              onDeletePersonal: section.isPersonal && c.personalId != null
                  ? () => onDeletePersonalContact(c.personalId!)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.item,
    this.onEditPersonal,
    this.onDeletePersonal,
  });

  final _ContactItem item;
  final VoidCallback? onEditPersonal;
  final VoidCallback? onDeletePersonal;

  bool get _hasPhone => item.phone.trim().isNotEmpty && item.phone != 'N/A';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(item.icon),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(item.phone),
        onTap: _hasPhone ? () => _copyPhone(context) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasPhone)
              IconButton(
                tooltip: 'Copy number',
                icon: const Icon(Icons.copy),
                onPressed: () => _copyPhone(context),
              ),
            if (onEditPersonal != null)
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit),
                onPressed: onEditPersonal,
              ),
            if (onDeletePersonal != null)
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete),
                onPressed: onDeletePersonal,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyPhone(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: item.phone));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Number copied to clipboard')),
      );
  }
}

class _PersonalContactDialog extends StatefulWidget {
  const _PersonalContactDialog({
    required this.title,
    required this.confirmLabel,
    this.existingId,
    this.initialName = '',
    this.initialPhone = '',
  });

  final String title;
  final String confirmLabel;
  final String? existingId;
  final String initialName;
  final String initialPhone;

  @override
  State<_PersonalContactDialog> createState() => _PersonalContactDialogState();
}

class _PersonalContactDialogState extends State<_PersonalContactDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? 'Required' : null;
      _phoneError = phone.isEmpty ? 'Required' : null;
    });

    if (_nameError != null || _phoneError != null) return;

    final id =
        widget.existingId ?? DateTime.now().microsecondsSinceEpoch.toString();
    Navigator.of(
      context,
    ).pop(_PersonalContact(id: id, name: name, phone: phone));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: _nameError,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone number',
                hintText: 'e.g. 09XXXXXXXXX',
                errorText: _phoneError,
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<_PersonalContact?>(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

class _ContactSection {
  const _ContactSection({
    required this.title,
    required this.contacts,
    this.isPersonal = false,
  });

  final String title;
  final List<_ContactItem> contacts;
  final bool isPersonal;
}

class _ContactItem {
  const _ContactItem({
    required this.icon,
    required this.name,
    required this.phone,
    this.personalId,
  });

  final IconData icon;
  final String name;
  final String phone;

  final String? personalId;
}

class _PersonalContact {
  const _PersonalContact({
    required this.id,
    required this.name,
    required this.phone,
  });

  final String id;
  final String name;
  final String phone;
}

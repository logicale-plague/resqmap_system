import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';
import 'package:kalig_onan_evac_system/feature/page/current_center_page.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/widgets/evac_center_item.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  var count = 4;

  @override
  Widget build(BuildContext context) {
    final evacCenter = ref.watch(allCentersProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        centerTitle: false,
        leading: Builder(
          builder: (context) =>
              IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/map'),
            icon: Icon(Icons.abc_sharp),
          ),
          IconButton(
            onPressed: () => context.push('/dashboard'),
            icon: Icon(Icons.dashboard),
          ),
        ],
      ),
      body: evacCenter.maybeWhen(
        data: (data) {
          return SafeArea(
            child: Center(
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final center = data[index];
                  return EvacCenterItem(
                    center: center,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EvacCenterDetailsPage(center: center),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
        orElse: () {
          return;
        },
      ),
    );
  }
}

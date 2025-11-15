
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:stepcount/features/home/bloc/step_bloc.dart' as step_bloc;
import 'package:stepcount/models/step_record.dart';
import 'package:stepcount/models/step_source.dart';

class HomeScreen extends StatelessWidget {
  final int stepGoal = 10000;

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Tracker'),
        backgroundColor: Colors.blue,
      ),
      body: BlocBuilder<step_bloc.StepBloc, step_bloc.StepState>(
        builder: (context, state) {
          if (state is step_bloc.StepInitial || state is step_bloc.StepLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is step_bloc.PermissionsNotGranted) {
            return _buildPermissionDeniedView(context);
          }

          if (state is step_bloc.StepTrackingActive) {
            return _buildTrackingView(context, state);
          }
          if (state is step_bloc.StepError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<step_bloc.StepBloc>().add(step_bloc.InitializeStepTracking());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }

  Widget _buildPermissionDeniedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Permissions Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This app requires the following permissions to track your steps:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildPermissionItem('Body Sensors', Icons.sensors),
            _buildPermissionItem('Activity Recognition', Icons.directions_walk),
            _buildPermissionItem('Location', Icons.location_on),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<step_bloc.StepBloc>().add(step_bloc.RequestPermissions());
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Grant Permissions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTrackingView(BuildContext context, step_bloc.StepTrackingActive state) {
    final progress = (state.totalSteps / stepGoal).clamp(0.0, 1.0);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '${state.totalSteps}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'steps',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? Colors.green : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Goal: $stepGoal steps (${(progress * 100).toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Source Indicator
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      state.source == StepSource.pedometer
                          ? Icons.phone_android
                          : Icons.favorite,
                      color: state.source == StepSource.pedometer
                          ? Colors.blue
                          : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Current Source: ${state.source == StepSource.pedometer ? "Pedometer" : "Health App"}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Health Connection Button
            ElevatedButton.icon(
              onPressed: () {
                if (state.isHealthConnected) {
                  context.read<step_bloc.StepBloc>().add(step_bloc.DisconnectFromHealth());
                } else {
                  context.read<step_bloc.StepBloc>().add(step_bloc.ConnectToHealth());
                }
              },
              icon: Icon(
                state.isHealthConnected ? Icons.link_off : Icons.link,
              ),
              label: Text(
                state.isHealthConnected
                    ? 'Disconnect Health App'
                    : 'Connect Health App',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: state.isHealthConnected
                    ? Colors.red
                    : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Step Records
            const Text(
              'Step Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            state.records.isEmpty
                ? const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No records yet. Start walking!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.records.length,
              itemBuilder: (context, index) {
                final record = state.records[state.records.length - 1 - index];
                return _buildStepRecordItem(record);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRecordItem(StepRecord record) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          record.source == 'pedometer' ? Icons.phone_android : Icons.favorite,
          color: record.source == 'pedometer' ? Colors.blue : Colors.red,
        ),
        title: Text(
          '${record.value} steps',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${dateFormat.format(record.startTime)} - ${dateFormat.format(record.endTime)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              record.source.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: record.source == 'pedometer' ? Colors.blue : Colors.red,
              ),
            ),
            if (!record.isSync)
              const Icon(Icons.sync_disabled, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
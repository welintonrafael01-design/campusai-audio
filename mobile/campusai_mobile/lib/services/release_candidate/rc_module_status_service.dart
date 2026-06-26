import 'rc_models.dart';

class RcModuleStatusService {
  const RcModuleStatusService();

  List<RcModuleStatus> buildModuleStatuses() => const [
        RcModuleStatus(module: 'Backend', notes: ['py_compile requerido']),
        RcModuleStatus(module: 'Flutter', notes: ['flutter analyze requerido']),
        RcModuleStatus(module: 'Teacher Studio'),
        RcModuleStatus(module: 'Student Studio'),
        RcModuleStatus(module: 'AudioBook'),
        RcModuleStatus(module: 'Voice'),
        RcModuleStatus(module: 'CampusAI'),
        RcModuleStatus(module: 'Marketplace', status: 'foundation'),
        RcModuleStatus(module: 'Institution', status: 'foundation'),
        RcModuleStatus(module: 'Gamification'),
        RcModuleStatus(module: 'Security'),
        RcModuleStatus(module: 'Performance'),
        RcModuleStatus(module: 'QA'),
        RcModuleStatus(module: 'Deployment'),
      ];
}

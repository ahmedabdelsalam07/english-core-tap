/// Non-web stub: platform engines report sound levels natively.
class MicLevelProbeImpl {
  bool get isRunning => false;

  Future<bool> start(void Function(double level) onLevel) async => false;

  void stop() {}
}

MicLevelProbeImpl createProbe() => MicLevelProbeImpl();

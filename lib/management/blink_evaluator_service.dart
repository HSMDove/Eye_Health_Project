import 'blink_counter.dart';
import 'blink_evaluator.dart';

class BlinkEvaluatorService {
  BlinkEvaluatorService._privateConstructor();

  static final BlinkEvaluatorService instance = BlinkEvaluatorService._privateConstructor();

  final BlinkEvaluator blinkEvaluator = BlinkEvaluator(
    blinkCounter: BlinkCounter(),
    onEvaluationComplete: (String status) {},
  );

  void startEvaluation() {
    blinkEvaluator.startEvaluation();
  }

  void stopEvaluation() {
    blinkEvaluator.stopEvaluation();
  }

  void updateTimings({required int newIntervalSeconds, required int newEvaluationDurationSeconds}) {
    blinkEvaluator.updateTimings(
      newIntervalSeconds: newIntervalSeconds,
      newEvaluationDurationSeconds: newEvaluationDurationSeconds,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_app/utils/snackbar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_utils.dart';

class ResetSettingsButton extends ConsumerStatefulWidget {
  const ResetSettingsButton({super.key});

  @override
  ResetSettingsButtonState createState() => ResetSettingsButtonState();
}

class ResetSettingsButtonState extends ConsumerState<ResetSettingsButton>
    with TickerProviderStateMixin {
  bool _isResetting = false; // 初期化中かどうか
  bool _isResetComplete = false; // 初期化完了かどうか
  late final AnimationController _animationController;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    // アニメーションコントローラの設定
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _rotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
  }

  Future<void> _resetApp() async {
    if (_isResetting) return; // すでに処理中の場合は早期リターン

    setState(() {
      _isResetting = true; // 初期化開始
    });

    try {
      // 非同期処理を実行
      final result = await AppUtils.reset(ref);

      // ここで mounted チェックをしてから context を使う
      if (!mounted) return;

      // 初期化結果に応じてSnackbar表示
      if (result) {
        SnackBarHelper.success(context, '初期化に成功しました');
      } else {
        SnackBarHelper.error(context, '初期化に失敗しました');
      }

      // 初期化処理が終わった後の状態更新
      _updateResetState(true);

      // 3秒後に完了状態をリセット
      await Future.delayed(const Duration(seconds: 3));

      // リセット完了状態を元に戻す
      if (!mounted) return; // ここでも mounted チェックを行う
      _updateResetState(false); // 完了状態を元に戻す
    } catch (e) {
      // エラーハンドリング
      if (!mounted) return; // エラー時も mounted チェック
      SnackBarHelper.error(context, '初期化に失敗しました: $e');
      _updateResetState(false); // エラーが発生した場合もリセット
    }
  }

  // 状態を一度に更新するためのヘルパー関数
  void _updateResetState(bool isComplete) {
    if (!mounted) return; // ウィジェットがマウントされていない場合にリターン
    setState(() {
      _isResetting = false;
      _isResetComplete = isComplete;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 左側のタイトル
              Text(
                'データを初期化',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                ),
              ),
              // 右側にボタンとアイコン
              Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isResetting
                        ? AnimatedBuilder(
                            key: const ValueKey('loadingIcon'),
                            animation: _rotation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotation.value * 6.3,
                                child: const Icon(Icons.refresh,
                                    color: Colors.grey),
                              );
                            },
                          )
                        : _isResetComplete
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                key: ValueKey('checkIcon'),
                              )
                            : null,
                  ),
                  // ボタン「実行」
                  ElevatedButton(
                    onPressed: _resetApp,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    child: const Text('実行'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

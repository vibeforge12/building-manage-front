import 'package:flutter/material.dart';

/// 한 줄에 들어가도록 글자 크기를 줄여서 보여준다.
///
/// 말줄임(`…`)만 쓰면 긴 건물명이 앞 몇 글자만 남아 어느 건물인지 알 수 없다.
/// 그렇다고 [FittedBox] 로 무한정 줄이면 이름이 길수록 읽을 수 없게 작아진다.
/// 그래서 [minFontSize] 까지만 줄이고, 그래도 안 들어가면 그때 말줄임한다.
///
/// 크기는 실제 폭으로 계산한다. 글자 수로 어림잡으면 한글·영문·숫자의 폭이 달라
/// 같은 길이라도 어떤 이름은 넘치고 어떤 이름은 여백이 남는다.
class ShrinkToFitText extends StatelessWidget {
  const ShrinkToFitText(
    this.text, {
    super.key,
    required this.style,
    this.minFontSize = 20,
    this.textAlign,
  });

  final String text;

  /// 줄이기 전의 기준 스타일. `fontSize` 가 최대 크기가 된다.
  final TextStyle style;

  /// 여기까지만 줄인다. 더 줄여야 들어가는 경우에는 말줄임으로 넘어간다.
  final double minFontSize;

  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final maxFontSize = style.fontSize ?? 14;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 폭을 알 수 없으면(무한 제약) 계산이 무의미하므로 기준 크기 그대로 둔다.
        if (!constraints.hasBoundedWidth) {
          return Text(text, style: style, maxLines: 1, textAlign: textAlign);
        }

        final scale = MediaQuery.textScalerOf(context);
        var fontSize = maxFontSize;

        // 1pt 씩 줄이며 한 줄에 들어가는 첫 크기를 찾는다.
        // 이분 탐색을 쓰지 않는 것은 후보가 최대 (maxFontSize - minFontSize) 개뿐이라
        // 차이가 없고, 단순한 쪽이 읽기 쉬워서다.
        while (fontSize > minFontSize) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style.copyWith(fontSize: fontSize)),
            maxLines: 1,
            textDirection: Directionality.of(context),
            textScaler: scale,
          )..layout();
          if (painter.width <= constraints.maxWidth) break;
          fontSize -= 1;
        }

        return Text(
          text,
          style: style.copyWith(fontSize: fontSize),
          maxLines: 1,
          // minFontSize 까지 줄여도 안 들어가는 아주 긴 이름의 최후 수단.
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
        );
      },
    );
  }
}

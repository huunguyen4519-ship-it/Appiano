import 'package:appiano/theory/notation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const letters = LetterNotation();
  const solfege = SolfegeNotation();
  const jianpu = JianpuNotation();

  test('ký âm chữ: chỉ Đô có quãng tám', () {
    expect(letters.labelFor(60), 'C4');
    expect(letters.labelFor(62), 'D');
    expect(letters.labelFor(64), 'E');
    expect(letters.labelFor(72), 'C5');
  });

  test('phím đen không có nhãn', () {
    expect(letters.labelFor(61), isNull);
    expect(solfege.labelFor(61), isNull);
    expect(jianpu.labelFor(61), isNull);
  });

  test('xướng âm Đô Rê Mi', () {
    expect(solfege.labelFor(60), 'Đô');
    expect(solfege.labelFor(65), 'Fa');
    expect(solfege.labelFor(71), 'Si');
  });

  test('Jianpu: quãng tám 4 không chấm, cao hơn chấm trên, thấp hơn chấm dưới', () {
    expect(jianpu.labelFor(60), '1');
    expect(jianpu.labelFor(67), '5');
    expect(jianpu.labelFor(72), '1̇');
    expect(jianpu.labelFor(48), '1̣');
  });

  test('mỗi kiểu có mã riêng để lưu cài đặt', () {
    final ids = notationChoices.map((n) => n.id).toSet();
    expect(ids.length, notationChoices.length);
  });
}

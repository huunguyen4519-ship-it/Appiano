import 'lesson.dart';

/// Các bước một nốt, từ danh sách nốt và số ngón cùng độ dài.
List<LessonStep> _seq(List<int> notes, List<int> fingers) => [
      for (var i = 0; i < notes.length; i++)
        LessonStep([notes[i]], [fingers[i]]),
    ];

/// Bài 8: tay phải theo giai điệu, tay trái đệm hợp âm ở đầu mỗi ô nhịp.
/// Mỗi ô nhịp bắt đầu bằng một bước gồm hợp âm tay trái và nốt đầu tiên của tay phải.
List<LessonStep> _bai8Steps() {
  const melody = [64, 64, 65, 67, 67, 65, 64, 62, 60, 60, 62, 64, 64, 62, 62];
  const fingers = [3, 3, 4, 5, 5, 4, 3, 2, 1, 1, 2, 3, 3, 2, 2];
  const bassC = [48, 52, 55]; // C3 E3 G3
  const bassG = [55, 59, 62]; // G3 B3 D4
  return [
    for (var i = 0; i < melody.length; i++)
      if (i % 4 == 0)
        LessonStep(
          [...(i % 8 == 0 ? bassC : bassG), melody[i]],
          [1, 3, 5, fingers[i]],
        )
      else
        LessonStep([melody[i]], [fingers[i]]),
  ];
}

/// Giáo trình có sẵn. Số MIDI: C4 = 60. Số ngón là tay phải, trừ khi ghi chú khác.
final List<Lesson> lessons = [
  Lesson(
    id: 'bai-01-ban-phim',
    title: 'Bài 1: Làm quen bàn phím',
    description: 'Phím trắng, phím đen, nhóm phím đen và quãng tám',
    theory: [
      'Bàn phím có phím trắng và phím đen xen kẽ liên tục.',
      'Phím đen chia thành nhóm 2 phím và nhóm 3 phím.',
      'Phím trắng nằm bên trái nhóm 2 phím đen là nốt C (Đô).',
      'Quãng tám là khoảng cách từ một nốt đến nốt cùng tên ở cao hơn hoặc thấp hơn.',
      'Trên điện thoại, vuốt ngang để chuyển qua lại giữa các quãng tám.',
    ],
    tips: [
      'Nhầm nhóm 2 phím đen với nhóm 3 phím đen khi vuốt quá nhanh.',
      'Không nhận ra nốt cùng tên ở các quãng tám khác nhau.',
    ],
    steps: _seq(
      [60, 62, 64, 65, 67, 69, 71, 72],
      [1, 2, 3, 1, 2, 3, 4, 5],
    ),
  ),
  Lesson(
    id: 'bai-02-ten-not',
    title: 'Bài 2: Tên nốt C D E F G A B',
    description: 'Ghi nhớ vị trí và tên 7 nốt cơ bản',
    theory: [
      'Có 7 nốt cơ bản: C (Đô), D (Rê), E (Mi), F (Fa), G (Sol), A (La), B (Si).',
      'Nốt C nằm ngay trước nhóm 2 phím đen; nốt D nằm giữa 2 phím đen đó.',
      'Nốt E nằm ngay sau nhóm 2 phím đen.',
      'Nốt F nằm ngay trước nhóm 3 phím đen; sau đó là G, A, B.',
      'Thứ tự 7 nốt lặp lại liên tục từ trái sang phải.',
    ],
    tips: [
      'Nhầm nốt F với nốt C vì cả hai đều nằm ngay trước một nhóm phím đen.',
      'Quên thứ tự tên chữ khi đi xuống.',
    ],
    steps: _seq(
      [60, 62, 64, 65, 67, 69, 71, 72, 71, 69, 67, 65, 64, 62, 60],
      [1, 2, 3, 1, 2, 3, 4, 5, 4, 3, 2, 1, 3, 2, 1],
    ),
  ),
  Lesson(
    id: 'bai-03-truong-do-nhip',
    title: 'Bài 3: Trường độ và nhịp',
    description: 'Nốt tròn, trắng, đen, móc; nhịp 4/4',
    theory: [
      'Nốt tròn ngân 4 phách, nốt trắng 2 phách, nốt đen 1 phách, nốt móc đơn 0,5 phách.',
      'Nhịp 4/4 có 4 phách trong một ô nhịp; phách đầu là phách mạnh.',
      'Nhịp 3/4 có 3 phách trong một ô nhịp; phách đầu là phách mạnh.',
      'Khi luyện, hãy đếm phách đều đặn trong đầu.',
    ],
    tips: [
      'Bài này hiện chỉ kiểm tra đúng nốt. Phần giữ nhịp sẽ thêm sau.',
      'Nhấp nhả phím quá nhanh làm mất độ ngân của nốt trắng và nốt tròn.',
    ],
    steps: _seq(
      [60, 60, 67, 67, 69, 69, 67, 65, 65, 64, 64, 62, 62, 60],
      [1, 1, 5, 5, 1, 1, 5, 4, 4, 3, 3, 2, 2, 1],
    ),
  ),
  Lesson(
    id: 'bai-04-so-ngon',
    title: 'Bài 4: Số ngón tay',
    description: 'Quy ước đánh số ngón và luồn ngón cái',
    theory: [
      'Quy ước số ngón: 1 (cái), 2 (trỏ), 3 (giữa), 4 (áp út), 5 (út).',
      'Ngón cái (ngón 1) luân chuyển vị trí bàn tay trên bàn phím.',
      'Luồn ngón cái: đưa ngón 1 xuống dưới ngón 3 hoặc ngón 4 để chuyển nốt.',
      'Giữ cổ tay thả lỏng, không gồng cứng khi di chuyển ngón.',
    ],
    tips: [
      'Nhấc cả bàn tay lên thay vì chủ động luồn ngón cái bên dưới ngón 3.',
      'Bài này chỉ luyện tay phải. Tay trái sẽ thêm ở bài sau.',
    ],
    steps: _seq(
      [60, 62, 64, 65, 67, 65, 64, 62, 60],
      [1, 2, 3, 1, 2, 1, 3, 2, 1],
    ),
  ),
  Lesson(
    id: 'bai-05-thang-am-do',
    title: 'Bài 5: Thang âm Đô trưởng',
    description: 'Nửa cung, cung và thang âm C Major đi lên, đi xuống',
    theory: [
      'Thang âm là chuỗi nốt sắp xếp theo cao độ tăng hoặc giảm.',
      'Hai phím liền kề (kể cả phím đen) cách nhau nửa cung.',
      'Hai nửa cung gộp lại thành một cung.',
      'Thang Đô trưởng: Cung - Cung - Nửa cung - Cung - Cung - Cung - Nửa cung.',
      'Thang Đô trưởng không dùng phím đen nào.',
    ],
    tips: [
      'Quên luồn ngón cái tại nốt F4 khi đi lên, khiến thiếu ngón cho các nốt sau.',
      'Tốc độ ngón không đều, nốt dài nốt ngắn lẫn lộn.',
    ],
    steps: _seq(
      [60, 62, 64, 65, 67, 69, 71, 72, 72, 71, 69, 67, 65, 64, 62, 60],
      [1, 2, 3, 1, 2, 3, 4, 5, 5, 4, 3, 2, 1, 3, 2, 1],
    ),
  ),
  Lesson(
    id: 'bai-06-hop-am',
    title: 'Bài 6: Hợp âm C, F, G, Am',
    description: 'Rải từng nốt và bấm đồng thời 3 nốt',
    theory: [
      'Hợp âm ba gồm 3 nốt, vang cùng lúc hoặc rải nối tiếp.',
      'C (Đô trưởng): C - E - G.',
      'F (Fa trưởng): F - A - C.',
      'G (Sol trưởng): G - B - D.',
      'Am (La thứ): A - C - E.',
    ],
    tips: [
      'Các nốt của hợp âm đồng thời không chạm cùng một lúc trên màn hình.',
      'Nhầm nốt giữa của hợp âm G: bấm C thay vì B.',
    ],
    steps: [
      ..._seq(
        [60, 64, 67, 65, 69, 72, 67, 71, 74, 69, 72, 76],
        [1, 3, 5, 1, 3, 5, 1, 3, 5, 1, 3, 5],
      ),
      const LessonStep([60, 64, 67], [1, 3, 5]),
      const LessonStep([65, 69, 72], [1, 3, 5]),
      const LessonStep([67, 71, 74], [1, 3, 5]),
      const LessonStep([69, 72, 76], [1, 3, 5]),
    ],
  ),
  Lesson(
    id: 'bai-07-dao-hop-am',
    title: 'Bài 7: Đảo hợp âm và hợp âm đệm',
    description: 'Đổi thế hợp âm để tay di chuyển ít nhất',
    theory: [
      'Thế nguyên bản: nốt gốc ở dưới cùng (C nguyên bản là C - E - G).',
      'Đảo 1: đưa nốt gốc lên cao nhất (C đảo 1 là E - G - C).',
      'Đảo 2: đưa nốt giữa lên cao nhất (C đảo 2 là G - C - E).',
      'Đảo hợp âm giúp tay di chuyển khoảng cách ngắn nhất giữa các hợp âm.',
    ],
    tips: [
      'Nhấc cả bàn tay đi xa thay vì giữ các nốt chung giữa hai hợp âm.',
      'Dùng sai thế ngón khi chuyển sang hợp âm đảo thế 2.',
    ],
    steps: [
      const LessonStep([60, 64, 67], [1, 3, 5]),
      const LessonStep([60, 64, 69], [1, 3, 5]),
      const LessonStep([60, 65, 69], [1, 2, 5]),
      const LessonStep([59, 62, 67], [1, 2, 5]),
    ],
  ),
  Lesson(
    id: 'bai-08-hai-tay',
    title: 'Bài 8: Giai điệu và hợp âm đệm',
    description: 'Ghép tay phải và tay trái trong một bài ngắn',
    theory: [
      'Luyện từng tay riêng trước, rồi mới ghép hai tay.',
      'Tay phải đảm nhận giai điệu chính.',
      'Tay trái đánh âm trầm và hợp âm đệm ở quãng tám thấp.',
      'Khi mới ghép, chơi thật chậm và đếm phách to.',
    ],
    tips: [
      'Ghép hai tay khi tay phải chưa thuộc giai điệu.',
      'Tay trái bị cuốn theo nhịp tay phải, làm mất nhịp đệm đều.',
      'Bài này gộp hợp âm tay trái với nốt đầu của ô nhịp, nên bấm nhiều phím cùng lúc.',
    ],
    steps: _bai8Steps(),
  ),
  Lesson(
    id: 'bai-09-doc-khuong',
    title: 'Bài 9: Đọc nốt khóa Sol và khóa Fa',
    description: 'Nhận diện nốt trên khuông nhạc (luyện theo tên nốt)',
    theory: [
      'Khuông nhạc có 5 dòng kẻ và 4 khe, tính từ dưới lên.',
      'Khóa Sol dành cho tay phải; các dòng là E - G - B - D - F.',
      'Khóa Fa dành cho tay trái; các dòng là G - B - D - F - A (tính từ dòng dưới).',
      'Mẹo nhớ 4 khe của khóa Sol từ dưới lên: F - A - C - E.',
      'Phần hiển thị khuông nhạc sẽ thêm sau. Hiện bài này luyện theo tên nốt.',
    ],
    tips: [
      'Nhầm nốt giữa khóa Sol và khóa Fa.',
      'Đếm dòng kẻ từ trên xuống thay vì từ dưới lên.',
    ],
    steps: [
      ..._seq([64, 67, 71, 74, 77], [1, 2, 3, 4, 5]),
      ..._seq([43, 47, 50, 53, 57], [5, 4, 3, 2, 1]),
    ],
  ),
  Lesson(
    id: 'bai-10-thang-sol-fa',
    title: 'Bài 10: Thang âm Sol trưởng và Fa trưởng',
    description: 'Dấu thăng, dấu giáng và các phím đen trong thang âm',
    theory: [
      'Dấu thăng (#) nâng nốt lên nửa cung; dấu giáng (b) hạ nốt xuống nửa cung.',
      'Sol trưởng có một dấu thăng ở nốt F: G A B C D E F# G.',
      'Fa trưởng có một dấu giáng ở nốt B: F G A Bb C D E F.',
    ],
    tips: [
      'Quên bấm phím đen F# và vẫn bấm F trắng trong thang Sol trưởng.',
      'Dùng ngón cái để bấm phím đen Bb4 trong thang Fa trưởng, gây vướng tay. Nên dùng ngón 4.',
    ],
    steps: [
      ..._seq(
        [67, 69, 71, 72, 74, 76, 78, 79],
        [1, 2, 3, 1, 2, 3, 4, 5],
      ),
      ..._seq(
        [65, 67, 69, 70, 72, 74, 76, 77],
        [1, 2, 3, 4, 1, 2, 3, 4],
      ),
    ],
  ),
  Lesson(
    id: 'scale-up',
    title: 'Thang âm đi lên',
    description: 'C D E F G A B C',
    steps: _seq(
      [60, 62, 64, 65, 67, 69, 71, 72],
      [1, 2, 3, 1, 2, 3, 4, 5],
    ),
  ),
  Lesson(
    id: 'scale-down',
    title: 'Thang âm đi xuống',
    description: 'C B A G F E D C',
    steps: _seq(
      [72, 71, 69, 67, 65, 64, 62, 60],
      [5, 4, 3, 2, 1, 3, 2, 1],
    ),
  ),
  Lesson(
    id: 'c-chord',
    title: 'Hợp âm Đô trưởng',
    description: 'C E G, rồi quay lại',
    steps: _seq([60, 64, 67, 64, 60], [1, 3, 5, 3, 1]),
  ),
  Lesson(
    id: 'ode-to-joy',
    title: 'Niềm vui (đoạn đầu)',
    description: 'Giai điệu quen thuộc, 15 nốt',
    steps: _seq(
      [64, 64, 65, 67, 67, 65, 64, 62, 60, 60, 62, 64, 64, 62, 62],
      [3, 3, 4, 5, 5, 4, 3, 2, 1, 1, 2, 3, 3, 2, 2],
    ),
  ),
];

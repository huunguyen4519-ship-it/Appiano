# Định dạng bài học để nạp vào Appiano

App nhận hai loại file: **JSON** (bài tự soạn) và **MIDI** (`.mid`, `.midi`).

## JSON

```json
{
  "title": "Tên bài",
  "description": "Mô tả ngắn",
  "theory": ["Ý lý thuyết 1", "Ý lý thuyết 2"],
  "tips": ["Lỗi thường gặp 1"],
  "steps": [
    { "notes": ["C4"], "fingers": [1] },
    { "notes": ["C4", "E4", "G4"], "fingers": [1, 3, 5] },
    { "notes": [67] }
  ]
}
```

- `title` là bắt buộc. `description`, `theory`, `tips` là tùy chọn.
- `steps` là bắt buộc, tối đa 500 bước. Mỗi bước là một nốt hoặc một hợp âm (nhiều nốt bấm cùng lúc).
- `notes`: tên nốt như `C4`, `F#4`, `Bb4` (C4 là Đô giữa), hoặc số MIDI từ 21 đến 108.
- `fingers` là tùy chọn. Nếu có thì phải có đúng số phần tử bằng `notes`, mỗi số từ 1 đến 5.
- File tối đa 1 MB.

## MIDI

- Đọc được file MIDI định dạng 0 hoặc 1 (không hỗ trợ SMPTE).
- Các nốt bắt đầu cùng một thời điểm được gom thành một bước (hợp âm).
- MIDI không có số ngón, nên bước không hiển thị số ngón.
- Kênh trống (kênh 10) bị bỏ qua. Tempo và nhịp không được đọc.

## Lỗi thường gặp

App báo lỗi bằng tiếng Việt, nêu rõ bước nào sai. Ví dụ: "Bước 3 có nốt không hợp lệ: H9".

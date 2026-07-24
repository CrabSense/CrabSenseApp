/**
 * CrabSense — lưu báo cáo CSV/JSON vào folder Drive cố định.
 *
 * Folder: https://drive.google.com/drive/folders/1ChLUTQOsr_h4LuNEO5QqyEeoybWVfKan
 *
 * Cách deploy (một lần):
 * 1. Mở https://script.google.com → New project
 * 2. Dán toàn bộ file này vào Code.gs
 * 3. Đặt UPLOAD_SECRET trùng với --dart-define=DRIVE_UPLOAD_SECRET=...
 * 4. Deploy → New deployment → Type: Web app
 *    - Execute as: Me
 *    - Who has access: Anyone  (bảo vệ bằng secret, không để trống UPLOAD_SECRET)
 * 5. flutter run --dart-define=DRIVE_UPLOAD_WEBHOOK=<URL> --dart-define=DRIVE_UPLOAD_SECRET=<secret>
 *
 * Body POST JSON:
 *   { "secret": "...", "filename": "x.csv", "mimeType": "text/csv", "dataBase64": "..." }
 */
var FOLDER_ID = '1ChLUTQOsr_h4LuNEO5QqyEeoybWVfKan';
/** BẮT BUỘC đổi trước khi deploy — secret dài, ngẫu nhiên. */
var UPLOAD_SECRET = 'CHANGE_ME_TO_A_LONG_RANDOM_SECRET';

var MAX_BYTES = 2 * 1024 * 1024; // 2 MB
var ALLOWED_MIME = {
  'text/csv': true,
  'application/json': true,
  'text/plain': true
};

function doPost(e) {
  try {
    var body = JSON.parse(e.postData.contents);
    if (!UPLOAD_SECRET || UPLOAD_SECRET === 'CHANGE_ME_TO_A_LONG_RANDOM_SECRET') {
      return _json({ success: false, message: 'Server secret chưa cấu hình' });
    }
    if (!body.secret || body.secret !== UPLOAD_SECRET) {
      return _json({ success: false, message: 'Unauthorized' });
    }
    if (!body.dataBase64 || typeof body.dataBase64 !== 'string') {
      return _json({ success: false, message: 'Thiếu dataBase64' });
    }

    var filename = _safeFilename(body.filename);
    var mimeType = body.mimeType || 'text/csv';
    if (!ALLOWED_MIME[mimeType]) {
      return _json({ success: false, message: 'MIME không cho phép' });
    }

    var bytes = Utilities.base64Decode(body.dataBase64);
    if (bytes.length > MAX_BYTES) {
      return _json({ success: false, message: 'File quá lớn' });
    }

    var blob = Utilities.newBlob(bytes, mimeType, filename);
    var folder = DriveApp.getFolderById(FOLDER_ID);
    var file = folder.createFile(blob);
    return _json({
      success: true,
      fileId: file.getId(),
      name: file.getName(),
      url: file.getUrl()
    });
  } catch (err) {
    return _json({ success: false, message: String(err) });
  }
}

function doGet() {
  return _json({
    ok: true,
    folderId: FOLDER_ID,
    message: 'CrabSense Drive upload webhook (requires secret on POST)'
  });
}

function _safeFilename(name) {
  var raw = (name || ('report_' + Date.now() + '.csv')).toString();
  raw = raw.replace(/[\\\/\?\*\|<>":]/g, '_');
  if (raw.length > 120) raw = raw.substring(0, 120);
  if (!/\.(csv|json|txt)$/i.test(raw)) raw = raw + '.csv';
  return raw;
}

function _json(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

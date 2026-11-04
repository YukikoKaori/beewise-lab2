/** Error carrying an HTTP status and a stable machine-readable code. */
export class HttpError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

export const badRequest = (code, message) => new HttpError(400, code, message);
export const unauthorized = (message = 'Bạn cần đăng nhập để tiếp tục.') =>
  new HttpError(401, 'unauthenticated', message);
export const forbidden = (message = 'Bạn không có quyền thực hiện thao tác này.') =>
  new HttpError(403, 'permission_denied', message);
export const notFound = (code, message) => new HttpError(404, code, message);
export const conflict = (code, message) => new HttpError(409, code, message);
export const unavailable = (code, message) => new HttpError(503, code, message);

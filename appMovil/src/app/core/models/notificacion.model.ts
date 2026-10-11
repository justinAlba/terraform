export interface NotificacionRequest {
  email: string;
  subject: string;
  message: string;
}

export interface NotificacionResponse {
  messageId: string;
  mensaje: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegistroRequest {
  nombre: string;
  email: string;
  password: string;
}

export interface TokenResponse {
  token: string;
  tipo: string;
}

export interface JwtPayload {
  sub: string;
  rol?: string;
  id?: number;
  iat: number;
  exp: number;
}

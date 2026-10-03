export type Rol = 'ADMIN' | 'USUARIO';

export interface Usuario {
  id: number;
  nombre: string;
  email: string;
  rol: Rol;
  fechaCreacion: string;
}

export interface UsuarioRequest {
  nombre: string;
  email: string;
  password: string;
  rol: Rol;
}

export interface UsuarioUpdateRequest {
  nombre: string;
  email: string;
  password?: string;
  rol: Rol;
}

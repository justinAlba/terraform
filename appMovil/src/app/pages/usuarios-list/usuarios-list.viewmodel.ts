import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { Usuario } from '../../core/models/usuario.model';
import { UsuarioRepository } from '../../repositories/usuario.repository';

@Injectable()
export class UsuariosListViewModel {
  readonly usuarios$ = new BehaviorSubject<Usuario[]>([]);
  readonly cargando$ = new BehaviorSubject<boolean>(false);
  readonly error$ = new BehaviorSubject<string | null>(null);

  constructor(private usuarioRepository: UsuarioRepository) {}

  cargar(): void {
    this.cargando$.next(true);
    this.error$.next(null);
    this.usuarioRepository.listar().subscribe({
      next: (usuarios) => {
        this.usuarios$.next(usuarios);
        this.cargando$.next(false);
      },
      error: () => {
        this.error$.next('No se pudo cargar la lista de usuarios.');
        this.cargando$.next(false);
      },
    });
  }

  eliminar(id: number): void {
    this.usuarioRepository.eliminar(id).subscribe({
      next: () => this.cargar(),
      error: () => this.error$.next('No se pudo eliminar el usuario.'),
    });
  }
}

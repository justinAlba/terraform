import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { Configuracion } from '../../core/models/dashboard.model';
import { Usuario } from '../../core/models/usuario.model';
import { AuthRepository } from '../../repositories/auth.repository';
import { DashboardRepository } from '../../repositories/dashboard.repository';

export interface DashboardEstado {
  usuarios: Usuario[];
  perfil: Usuario | null;
  configuracion: Configuracion | null;
}

@Injectable()
export class DashboardViewModel {
  readonly estado$ = new BehaviorSubject<DashboardEstado>({ usuarios: [], perfil: null, configuracion: null });
  readonly cargando$ = new BehaviorSubject<boolean>(false);
  readonly error$ = new BehaviorSubject<string | null>(null);

  constructor(private dashboardRepository: DashboardRepository, private authRepository: AuthRepository) {}

  async cargar(): Promise<void> {
    const usuarioActual = await this.authRepository.obtenerUsuarioActual();
    if (!usuarioActual?.id) {
      this.error$.next('No se pudo identificar al usuario actual.');
      return;
    }

    this.cargando$.next(true);
    this.error$.next(null);

    this.dashboardRepository.cargar(usuarioActual.id).subscribe({
      next: ({ usuarios, perfil, configuracion }) => {
        this.estado$.next({ usuarios, perfil, configuracion });
        this.cargando$.next(false);
      },
      error: () => {
        this.error$.next('No se pudieron cargar los datos del dashboard.');
        this.cargando$.next(false);
      },
    });
  }
}

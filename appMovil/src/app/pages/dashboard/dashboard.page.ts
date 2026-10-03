import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { AuthRepository } from '../../repositories/auth.repository';
import { DashboardViewModel } from './dashboard.viewmodel';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.page.html',
  styleUrls: ['./dashboard.page.scss'],
  standalone: false,
  providers: [DashboardViewModel],
})
export class DashboardPage {
  readonly estado$ = this.viewModel.estado$;
  readonly cargando$ = this.viewModel.cargando$;
  readonly error$ = this.viewModel.error$;

  constructor(
    private viewModel: DashboardViewModel,
    private authRepository: AuthRepository,
    private router: Router
  ) {}

  ionViewWillEnter(): void {
    this.viewModel.cargar();
  }

  irAUsuarios(): void {
    this.router.navigateByUrl('/usuarios-list');
  }

  irASubirArchivo(): void {
    this.router.navigateByUrl('/upload');
  }

  async cerrarSesion(): Promise<void> {
    await this.authRepository.logout();
    this.router.navigateByUrl('/login');
  }
}

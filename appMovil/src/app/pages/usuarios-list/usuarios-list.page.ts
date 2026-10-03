import { Component } from '@angular/core';
import { AlertController } from '@ionic/angular';
import { Router } from '@angular/router';
import { AuthRepository } from '../../repositories/auth.repository';
import { Usuario } from '../../core/models/usuario.model';
import { UsuariosListViewModel } from './usuarios-list.viewmodel';

@Component({
  selector: 'app-usuarios-list',
  templateUrl: './usuarios-list.page.html',
  styleUrls: ['./usuarios-list.page.scss'],
  standalone: false,
  providers: [UsuariosListViewModel],
})
export class UsuariosListPage {
  readonly usuarios$ = this.viewModel.usuarios$;
  readonly cargando$ = this.viewModel.cargando$;
  readonly error$ = this.viewModel.error$;

  constructor(
    private viewModel: UsuariosListViewModel,
    private alertController: AlertController,
    private authRepository: AuthRepository,
    private router: Router
  ) {}

  ionViewWillEnter(): void {
    this.viewModel.cargar();
  }

  doRefresh(event: CustomEvent): void {
    this.viewModel.cargar();
    (event.target as HTMLIonRefresherElement).complete();
  }

  nuevoUsuario(): void {
    this.router.navigateByUrl('/usuario-form');
  }

  editarUsuario(usuario: Usuario): void {
    this.router.navigateByUrl(`/usuario-form/${usuario.id}`);
  }

  async confirmarEliminar(usuario: Usuario): Promise<void> {
    const alert = await this.alertController.create({
      header: 'Eliminar usuario',
      message: `Deseas eliminar a ${usuario.nombre}?`,
      buttons: [
        { text: 'Cancelar', role: 'cancel' },
        { text: 'Eliminar', role: 'destructive', handler: () => this.viewModel.eliminar(usuario.id) },
      ],
    });
    await alert.present();
  }

  async cerrarSesion(): Promise<void> {
    await this.authRepository.logout();
    this.router.navigateByUrl('/login');
  }
}

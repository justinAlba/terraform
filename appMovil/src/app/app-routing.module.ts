import { NgModule } from '@angular/core';
import { PreloadAllModules, RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './core/guards/auth.guard';

const routes: Routes = [
  {
    path: '',
    redirectTo: 'login',
    pathMatch: 'full',
  },
  {
    path: 'login',
    loadChildren: () => import('./pages/login/login.module').then((m) => m.LoginPageModule),
  },
  {
    path: 'register',
    loadChildren: () => import('./pages/register/register.module').then((m) => m.RegisterPageModule),
  },
  {
    path: 'usuarios-list',
    loadChildren: () =>
      import('./pages/usuarios-list/usuarios-list.module').then((m) => m.UsuariosListPageModule),
    canActivate: [AuthGuard],
  },
  {
    path: 'usuario-form',
    loadChildren: () =>
      import('./pages/usuario-form/usuario-form.module').then((m) => m.UsuarioFormPageModule),
    canActivate: [AuthGuard],
  },
  {
    path: 'usuario-form/:id',
    loadChildren: () =>
      import('./pages/usuario-form/usuario-form.module').then((m) => m.UsuarioFormPageModule),
    canActivate: [AuthGuard],
  },
  {
    path: 'dashboard',
    loadChildren: () => import('./pages/dashboard/dashboard.module').then((m) => m.DashboardPageModule),
    canActivate: [AuthGuard],
  },
  {
    path: 'upload',
    loadChildren: () => import('./pages/upload/upload.module').then((m) => m.UploadPageModule),
    canActivate: [AuthGuard],
  },
  {
    path: 'settings',
    loadChildren: () => import('./pages/settings/settings.module').then( m => m.SettingsPageModule)
  },
];

@NgModule({
  imports: [RouterModule.forRoot(routes, { preloadingStrategy: PreloadAllModules })],
  exports: [RouterModule],
})
export class AppRoutingModule {}

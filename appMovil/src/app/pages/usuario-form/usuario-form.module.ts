import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';

import { IonicModule } from '@ionic/angular/lazy';

import { UsuarioFormPageRoutingModule } from './usuario-form-routing.module';

import { UsuarioFormPage } from './usuario-form.page';

@NgModule({
  imports: [
    CommonModule,
    ReactiveFormsModule,
    IonicModule,
    UsuarioFormPageRoutingModule
  ],
  declarations: [UsuarioFormPage]
})
export class UsuarioFormPageModule {}

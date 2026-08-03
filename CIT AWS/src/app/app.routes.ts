import { Routes } from '@angular/router';
import { PanelIncidencias } from './components/panel-incidencias/panel-incidencias';
import { Login } from './components/login/login';
import { roleGuard } from './guard/role-guard';
import { Asistencia } from './components/asistencia/asistencia';
import { Register } from './components/register/register';
import { NotFound } from './components/not-found/not-found';
import { PanelAdmin } from './components/panel-admin/panel-admin/panel-admin';

export const routes: Routes = [
    {
        path: 'login',
        component: Login
    },

    {
        path: 'register',
        component: Register
    },

    {
        path: 'incidencias',
        component: PanelIncidencias,
        canActivate: [roleGuard],
        data: { rol: 'ADMINISTRADOR' }
    },

    {
        path: 'admin',
        component: PanelAdmin,
        canActivate: [roleGuard],
        data: { rol: 'ADMINISTRADOR' }
    },

    {
        path: 'asistencia',
        component: Asistencia,
        canActivate: [roleGuard],
        data: { rol: 'ALUMNO' }
    },

    {
        path: '',
        redirectTo: 'login',
        pathMatch: 'full'
    },

    { path: '404', component: NotFound },
    { path: '**', component: NotFound }
];
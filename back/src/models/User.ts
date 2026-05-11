import { Role } from '@prisma/client';

export interface User {
  id: string;
  nome: string;
  email: string;
  senha_hash: string;
  role: Role;
  criado_em: Date;
}

export interface PublicUser {
  id: string;
  nome: string;
  email: string;
  role: Role;
  criado_em: Date;
}

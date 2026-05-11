import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import type { User as PrismaUser } from '@prisma/client';
import { UserRepository } from '../repositories/UserRepository';
import { PublicUser } from '../models/User';

export class UserService {
  private userRepository: UserRepository;

  constructor() {
    this.userRepository = new UserRepository();
  }

  private formatUser(user: PrismaUser): PublicUser {
    return {
      id: user.id,
      nome: user.nome,
      email: user.email,
      role: user.role,
      criado_em: user.criado_em,
    };
  }

  async register(nome: string | undefined, email: string, password: string): Promise<PublicUser> {
    const existingUser = await this.userRepository.findByEmail(email);
    if (existingUser) {
      throw new Error('User already exists');
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await this.userRepository.create({
      nome: nome?.trim() || email.split('@')[0],
      email,
      senha_hash: hashedPassword,
      role: 'CLIENTE',
    });

    return this.formatUser(user);
  }

  async login(email: string, password: string): Promise<string> {
    const user = await this.userRepository.findByEmail(email);
    if (!user) {
      throw new Error('Invalid credentials');
    }

    const isValidPassword = await bcrypt.compare(password, user.senha_hash);
    if (!isValidPassword) {
      throw new Error('Invalid credentials');
    }

    return jwt.sign({ id: user.id, email: user.email, role: user.role }, process.env.JWT_SECRET || 'your_super_secret_jwt_key_here', {
      expiresIn: '1h',
    });
  }

  async getUserById(id: string): Promise<PublicUser | null> {
    const user = await this.userRepository.findById(id);
    if (!user) {
      return null;
    }
    return this.formatUser(user);
  }

  async getAllUsers(): Promise<PublicUser[]> {
    const users = await this.userRepository.getAll();
    return users.map(user => this.formatUser(user));
  }
}

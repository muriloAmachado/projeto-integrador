import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

interface AuthRequest extends Request {
  user?: any;
}

export const authenticateToken = (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.status(401).json({ message: 'Access token required' });

  // Use .trim() para remover espaços acidentais que o .env possa ter lido
  const secret = (process.env.JWT_SECRET || 'your_super_secret_jwt_key_here').trim();

  jwt.verify(token, secret, (err: any, user: any) => {
    if (err) {
      // Adicione este log para ver o nome exato do erro do JWT
      console.log("Erro interno do JWT:", err.name); 
      return res.status(403).json({ message: 'Invalid token', error: err.name });
    }
    req.user = user;
    next();
  });
};
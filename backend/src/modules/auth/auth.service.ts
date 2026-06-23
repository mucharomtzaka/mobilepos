import { Injectable, ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from '../../database/entities/user.entity';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { MerchantRegisterDto } from './dto/merchant-register.dto';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,
    private jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.userRepo.findOne({ where: { username: dto.username } });
    if (existing) throw new ConflictException('Username already exists');

    const hashed = await bcrypt.hash(dto.password, 10);
    const user = this.userRepo.create({
      name: dto.name,
      username: dto.username,
      password: hashed,
      role: dto.role || 'kasir',
      isActive: true,
      createdAt: new Date().toISOString(),
    });
    await this.userRepo.save(user);
    return this.generateToken(user);
  }

  async merchantRegister(dto: MerchantRegisterDto) {
    const existing = await this.userRepo.findOne({ 
      where: [{ username: dto.username }, { email: dto.email }] 
    });
    if (existing) throw new ConflictException('Username or email already exists');

    const hashed = await bcrypt.hash(dto.password, 10);
    const apiKey = this.generateApiKey();
    
    const user = this.userRepo.create({
      name: dto.name,
      username: dto.username,
      email: dto.email,
      password: hashed,
      role: 'merchant',
      isActive: true,
      createdAt: new Date().toISOString(),
      apiKey,
      phone: dto.phone,
      address: dto.address,
    });
    await this.userRepo.save(user);
    
    return {
      merchant: {
        id: user.id,
        name: user.name,
        username: user.username,
        email: user.email,
        role: user.role,
        apiKey,
        phone: user.phone,
        address: user.address,
      },
      message: 'Merchant registered successfully. Save your API key for sync configuration.',
    };
  }

  async login(dto: LoginDto) {
    const user = await this.userRepo.findOne({ where: { username: dto.username } });
    if (!user) throw new UnauthorizedException('Invalid credentials');

    const valid = await bcrypt.compare(dto.password, user.password);
    if (!valid) throw new UnauthorizedException('Invalid credentials');
    if (!user.isActive) throw new UnauthorizedException('Account is inactive');

    return this.generateToken(user);
  }

  private generateToken(user: User) {
    const payload = { sub: user.id, username: user.username, role: user.role };
    return {
      accessToken: this.jwtService.sign(payload),
      user: { id: user.id, name: user.name, username: user.username, role: user.role },
    };
  }

  private generateApiKey(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let key = 'mp_';
    for (let i = 0; i < 32; i++) {
      key += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return key;
  }
}

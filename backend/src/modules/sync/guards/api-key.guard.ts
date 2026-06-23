import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';

@Injectable()
export class ApiKeyGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const key = req.headers['x-api-key'];
    const expected = process.env.API_KEY || 'mobilepos-sync-key';
    if (!key || key !== expected) throw new UnauthorizedException('Invalid API key');
    return true;
  }
}

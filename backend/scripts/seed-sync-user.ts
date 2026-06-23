import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { AuthService } from '../src/modules/auth/auth.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const auth = app.get(AuthService);

  try {
    const result = await auth.register({
      name: 'Sync User',
      username: 'sync',
      password: 'sync123',
      role: 'admin',
    });
    console.log('Sync user created (id:' + result.user.id + ', username:' + result.user.username + ')');
  } catch (e: any) {
    if (e.message?.includes('already exists')) {
      console.log('Sync user already exists');
    } else {
      console.error('Error:', e.message);
    }
  }

  await app.close();
}
bootstrap();

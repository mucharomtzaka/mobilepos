import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BundlesController } from './bundles.controller';
import { BundlesService } from './bundles.service';
import { Bundle } from '../../database/entities/bundle.entity';
import { BundleItem } from '../../database/entities/bundle-item.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Bundle, BundleItem])],
  controllers: [BundlesController],
  providers: [BundlesService],
  exports: [BundlesService],
})
export class BundlesModule {}

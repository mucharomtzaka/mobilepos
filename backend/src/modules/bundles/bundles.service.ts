import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Bundle } from '../../database/entities/bundle.entity';
import { BundleItem } from '../../database/entities/bundle-item.entity';
import { CreateBundleDto } from './dto/create-bundle.dto';
import { UpdateBundleDto } from './dto/update-bundle.dto';

@Injectable()
export class BundlesService {
  constructor(
    @InjectRepository(Bundle)
    private bundleRepo: Repository<Bundle>,
    @InjectRepository(BundleItem)
    private bundleItemRepo: Repository<BundleItem>,
  ) {}

  async create(dto: CreateBundleDto) {
    const { items, ...data } = dto;
    const bundle = this.bundleRepo.create({
      ...data,
      isActive: data.isActive ?? true,
      createdAt: new Date().toISOString(),
    });
    const saved = await this.bundleRepo.save(bundle);

    if (items && items.length > 0) {
      const bundleItems = items.map(item =>
        this.bundleItemRepo.create({ bundleId: saved.id, ...item }),
      );
      await this.bundleItemRepo.save(bundleItems);
    }

    return this.findOne(saved.id);
  }

  async findAll() {
    return this.bundleRepo.find({ relations: ['items'] });
  }

  async findOne(id: number) {
    const bundle = await this.bundleRepo.findOne({
      where: { id },
      relations: ['items'],
    });
    if (!bundle) throw new NotFoundException('Bundle not found');
    return bundle;
  }

  async update(id: number, dto: UpdateBundleDto) {
    const bundle = await this.findOne(id);
    const { items, ...data } = dto;

    Object.assign(bundle, data);
    await this.bundleRepo.save(bundle);

    if (items) {
      await this.bundleItemRepo.delete({ bundleId: id });
      const bundleItems = items.map(item =>
        this.bundleItemRepo.create({ bundleId: id, ...item }),
      );
      await this.bundleItemRepo.save(bundleItems);
    }

    return this.findOne(id);
  }

  async remove(id: number) {
    const bundle = await this.findOne(id);
    return this.bundleRepo.remove(bundle);
  }
}

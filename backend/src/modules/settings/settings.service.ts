import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Setting } from '../../database/entities/setting.entity';
import { UpdateSettingDto } from './dto/update-setting.dto';

@Injectable()
export class SettingsService {
  constructor(
    @InjectRepository(Setting)
    private settingRepo: Repository<Setting>,
  ) {}

  async findAll() {
    return this.settingRepo.find();
  }

  async findOne(key: string) {
    const setting = await this.settingRepo.findOne({ where: { key } });
    if (!setting) throw new NotFoundException('Setting not found');
    return setting;
  }

  async update(key: string, dto: UpdateSettingDto) {
    let setting = await this.settingRepo.findOne({ where: { key } });
    if (setting) {
      setting.value = dto.value;
    } else {
      setting = this.settingRepo.create({ key, value: dto.value });
    }
    return this.settingRepo.save(setting);
  }
}

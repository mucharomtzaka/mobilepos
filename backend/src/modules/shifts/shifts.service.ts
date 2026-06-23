import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Shift } from '../../database/entities/shift.entity';
import { CreateShiftDto } from './dto/create-shift.dto';
import { UpdateShiftDto } from './dto/update-shift.dto';

@Injectable()
export class ShiftsService {
  constructor(
    @InjectRepository(Shift)
    private shiftRepo: Repository<Shift>,
  ) {}

  async create(dto: CreateShiftDto) {
    const shift = this.shiftRepo.create({
      ...dto,
      status: 'open',
    });
    return this.shiftRepo.save(shift);
  }

  async findAll() {
    return this.shiftRepo.find();
  }

  async findOne(id: number) {
    const shift = await this.shiftRepo.findOne({ where: { id } });
    if (!shift) throw new NotFoundException('Shift not found');
    return shift;
  }

  async update(id: number, dto: UpdateShiftDto) {
    const shift = await this.findOne(id);
    Object.assign(shift, dto);
    return this.shiftRepo.save(shift);
  }

  async remove(id: number) {
    const shift = await this.findOne(id);
    return this.shiftRepo.remove(shift);
  }
}

import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RestoTable } from '../../database/entities/table.entity';
import { CreateTableDto } from './dto/create-table.dto';

@Injectable()
export class TablesService {
  constructor(
    @InjectRepository(RestoTable)
    private tableRepo: Repository<RestoTable>,
  ) {}

  async create(dto: CreateTableDto) {
    const table = this.tableRepo.create({
      ...dto,
      capacity: dto.capacity ?? 4,
      isActive: dto.isActive ?? true,
      createdAt: new Date().toISOString(),
    });
    return this.tableRepo.save(table);
  }

  async findAll() {
    return this.tableRepo.find();
  }

  async findOne(id: number) {
    const table = await this.tableRepo.findOne({ where: { id } });
    if (!table) throw new NotFoundException('Table not found');
    return table;
  }

  async update(id: number, dto: CreateTableDto) {
    const table = await this.findOne(id);
    Object.assign(table, dto);
    return this.tableRepo.save(table);
  }

  async remove(id: number) {
    const table = await this.findOne(id);
    return this.tableRepo.remove(table);
  }
}

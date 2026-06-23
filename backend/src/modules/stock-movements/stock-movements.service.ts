import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { StockMovement } from '../../database/entities/stock-movement.entity';
import { CreateStockMovementDto } from './dto/create-stock-movement.dto';

@Injectable()
export class StockMovementsService {
  constructor(
    @InjectRepository(StockMovement)
    private stockMovementRepo: Repository<StockMovement>,
  ) {}

  async create(dto: CreateStockMovementDto) {
    const movement = this.stockMovementRepo.create({
      ...dto,
      createdAt: new Date().toISOString(),
    });
    return this.stockMovementRepo.save(movement);
  }

  async findAll(productId?: number) {
    const where = productId ? { productId } : {};
    return this.stockMovementRepo.find({ where, order: { createdAt: 'DESC' } });
  }

  async findOne(id: number) {
    const movement = await this.stockMovementRepo.findOne({ where: { id } });
    if (!movement) throw new NotFoundException('Stock movement not found');
    return movement;
  }

  async remove(id: number) {
    const movement = await this.findOne(id);
    return this.stockMovementRepo.remove(movement);
  }
}

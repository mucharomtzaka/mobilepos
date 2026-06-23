import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, FindOptionsWhere } from 'typeorm';
import { Order } from '../../database/entities/order.entity';
import { OrderItem } from '../../database/entities/order-item.entity';
import { Payment } from '../../database/entities/payment.entity';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderDto } from './dto/update-order.dto';
import { OrderQueryDto } from './dto/order-query.dto';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private orderRepo: Repository<Order>,
    @InjectRepository(OrderItem)
    private orderItemRepo: Repository<OrderItem>,
    @InjectRepository(Payment)
    private paymentRepo: Repository<Payment>,
  ) {}

  async create(dto: CreateOrderDto) {
    const { items, payments, ...orderFields } = dto;
    const order = this.orderRepo.create({
      ...orderFields,
      status: dto.status ?? 'completed',
      createdAt: new Date().toISOString(),
    });
    const saved = await this.orderRepo.save(order);

    if (items?.length) {
      const orderItems = items.map(i =>
        this.orderItemRepo.create({ ...i, orderId: saved.id }),
      );
      await this.orderItemRepo.save(orderItems);
    }

    if (payments?.length) {
      const paymentEntities = payments.map(p =>
        this.paymentRepo.create({ ...p, orderId: saved.id, createdAt: new Date().toISOString() }),
      );
      await this.paymentRepo.save(paymentEntities);
    }

    return this.findOne(saved.id);
  }

  async findAll(query: OrderQueryDto) {
    const { status, startDate, endDate, userId, shiftId, page = 1, limit = 20 } = query;
    const where: FindOptionsWhere<Order> = {};

    if (status) where.status = status;
    if (userId) where.userId = userId;
    if (shiftId) where.shiftId = shiftId;
    if (startDate && endDate) {
      where.createdAt = Between(startDate, endDate);
    }

    const [data, total] = await this.orderRepo.findAndCount({
      where,
      relations: ['items', 'payments', 'user', 'customer', 'table'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { data, total, page, limit };
  }

  async findOne(id: number) {
    const order = await this.orderRepo.findOne({
      where: { id },
      relations: ['items', 'payments', 'user', 'customer', 'table'],
    });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async update(id: number, dto: UpdateOrderDto) {
    const order = await this.orderRepo.findOne({ where: { id } });
    if (!order) throw new NotFoundException('Order not found');
    Object.assign(order, dto);
    return this.orderRepo.save(order);
  }

  async remove(id: number) {
    await this.orderItemRepo.delete({ orderId: id });
    await this.paymentRepo.delete({ orderId: id });
    const order = await this.findOne(id);
    return this.orderRepo.remove(order);
  }
}

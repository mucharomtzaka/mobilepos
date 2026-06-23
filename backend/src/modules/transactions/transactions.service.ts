import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Transaction } from '../../database/entities/transaction.entity';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { TransactionQueryDto } from './dto/transaction-query.dto';

@Injectable()
export class TransactionsService {
  constructor(
    @InjectRepository(Transaction)
    private transactionRepo: Repository<Transaction>,
  ) {}

  async create(dto: CreateTransactionDto) {
    const transaction = this.transactionRepo.create({
      ...dto,
      createdAt: new Date().toISOString(),
    });
    return this.transactionRepo.save(transaction);
  }

  async findAll(query: TransactionQueryDto) {
    const { type, startDate, endDate } = query;
    const where: any = {};

    if (type) where.type = type;
    if (startDate && endDate) {
      where.createdAt = Between(startDate, endDate);
    }

    return this.transactionRepo.find({ where, order: { createdAt: 'DESC' } });
  }

  async findOne(id: number) {
    const transaction = await this.transactionRepo.findOne({ where: { id } });
    if (!transaction) throw new NotFoundException('Transaction not found');
    return transaction;
  }

  async remove(id: number) {
    const transaction = await this.findOne(id);
    return this.transactionRepo.remove(transaction);
  }
}

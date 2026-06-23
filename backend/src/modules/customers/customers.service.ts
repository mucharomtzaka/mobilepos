import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like } from 'typeorm';
import { Customer } from '../../database/entities/customer.entity';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { UpdateCustomerDto } from './dto/update-customer.dto';

@Injectable()
export class CustomersService {
  constructor(
    @InjectRepository(Customer)
    private customerRepo: Repository<Customer>,
  ) {}

  async create(dto: CreateCustomerDto) {
    const customer = this.customerRepo.create({
      ...dto,
      createdAt: new Date().toISOString(),
    });
    return this.customerRepo.save(customer);
  }

  async findAll(search?: string) {
    if (search) {
      return this.customerRepo.find({
        where: [
          { name: Like(`%${search}%`) },
          { phone: Like(`%${search}%`) },
        ],
      });
    }
    return this.customerRepo.find();
  }

  async findOne(id: number) {
    const customer = await this.customerRepo.findOne({ where: { id } });
    if (!customer) throw new NotFoundException('Customer not found');
    return customer;
  }

  async update(id: number, dto: UpdateCustomerDto) {
    const customer = await this.findOne(id);
    Object.assign(customer, dto);
    return this.customerRepo.save(customer);
  }

  async remove(id: number) {
    const customer = await this.findOne(id);
    return this.customerRepo.remove(customer);
  }
}

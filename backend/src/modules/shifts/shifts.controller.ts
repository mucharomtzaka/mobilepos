import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ShiftsService } from './shifts.service';
import { CreateShiftDto } from './dto/create-shift.dto';
import { UpdateShiftDto } from './dto/update-shift.dto';

@ApiTags('Shifts')
@Controller('shifts')
@UseGuards(JwtAuthGuard)
export class ShiftsController {
  constructor(private shiftsService: ShiftsService) {}

  @Post()
  @ApiOperation({ summary: 'Create shift' })
  create(@Body() dto: CreateShiftDto) {
    return this.shiftsService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'List shifts' })
  findAll() {
    return this.shiftsService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get shift by id' })
  findOne(@Param('id') id: string) {
    return this.shiftsService.findOne(+id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update shift' })
  update(@Param('id') id: string, @Body() dto: UpdateShiftDto) {
    return this.shiftsService.update(+id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete shift' })
  remove(@Param('id') id: string) {
    return this.shiftsService.remove(+id);
  }
}

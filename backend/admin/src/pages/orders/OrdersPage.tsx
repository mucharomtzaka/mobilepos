import { useState, useEffect } from 'react'
import { AlertCircle, ShoppingCart, Search, Filter, X, Calendar } from 'lucide-react'
import api from '../../api/client'

interface OrderItem {
  id: string
  productId: number
  productName: string
  variantName?: string
  qty: number
  price: number
  subtotal: number
}

interface Payment {
  id: string
  method: string
  amount: number
}

interface Customer {
  name: string
  phone: string
}

interface Order {
  id: string
  orderNumber: string
  user: { name: string }
  total: number
  status: string
  createdAt: string
  items?: OrderItem[]
  payments?: Payment[]
  customer?: Customer
  discount?: number
  tax?: number
}

interface OrderQuery {
  page: number
  limit: number
  search?: string
  status?: string
  startDate?: string
  endDate?: string
}

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [totalItems, setTotalItems] = useState(0)
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [showFilters, setShowFilters] = useState(false)

  const fetchOrders = async () => {
    setLoading(true)
    setError('')
    try {
      const params = new URLSearchParams({
        page: page.toString(),
        limit: '20',
      })
      if (search) params.append('search', search)
      if (statusFilter) params.append('status', statusFilter)
      if (startDate) params.append('startDate', startDate)
      if (endDate) params.append('endDate', endDate)

      const res = await api.get(`/orders?${params.toString()}`)
      const data = res.data
      const items = Array.isArray(data) ? data : data.data || []
      setOrders(items)
      if (data.meta) {
        setTotalPages(data.meta.totalPages || Math.ceil(data.meta.total / 20) || 1)
        setTotalItems(data.meta.total || items.length)
      } else {
        setTotalItems(items.length)
        setTotalPages(1)
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Gagal memuat data')
    } finally {
      setLoading(false)
    }
  }

  const handleFilterChange = () => {
    setPage(1)
    fetchOrders()
  }

  const clearFilters = () => {
    setSearch('')
    setStatusFilter('')
    setStartDate('')
    setEndDate('')
    setPage(1)
    fetchOrders()
  }

  const hasActiveFilters = search || statusFilter || startDate || endDate

  useEffect(() => { fetchOrders() }, [page, search, statusFilter, startDate, endDate])

  const viewDetail = async (order: Order) => {
    try {
      const res = await api.get(`/orders/${order.id}`)
      setSelectedOrder(res.data)
    } catch {
      setSelectedOrder(order)
    }
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-center gap-3">
        <AlertCircle className="text-red-500" size={20} />
        <span className="text-red-700">{error}</span>
        <button onClick={fetchOrders} className="ml-auto bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm">Coba Lagi</button>
      </div>
    )
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <h1 className="text-2xl font-bold text-gray-800">Pesanan</h1>
        <button
          onClick={() => setShowFilters(!showFilters)}
          className={`flex items-center gap-2 px-3 py-2 border rounded-lg text-sm ${showFilters ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}
        >
          <Filter size={16} />
          <span>Filter</span>
          {hasActiveFilters && <span className="bg-red-500 text-white text-xs px-1.5 rounded-full">{([search, statusFilter, startDate, endDate].filter(Boolean).length)}</span>}
        </button>
      </div>

      {showFilters && (
        <div className="bg-gray-50 rounded-lg p-4 mb-4 space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Cari</label>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                <input
                  type="text"
                  value={search}
                  onChange={(e) => { setSearch(e.target.value); handleFilterChange(); }}
                  placeholder="No. Pesanan, Kasir, Pelanggan..."
                  className="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
              <select
                value={statusFilter}
                onChange={(e) => { setStatusFilter(e.target.value); handleFilterChange(); }}
                className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
              >
                <option value="">Semua Status</option>
                <option value="completed">Selesai</option>
                <option value="draft">Draft</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Tanggal Mulai</label>
              <div className="relative">
                <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => { setStartDate(e.target.value); handleFilterChange(); }}
                  className="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Tanggal Akhir</label>
              <div className="relative">
                <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                <input
                  type="date"
                  value={endDate}
                  onChange={(e) => { setEndDate(e.target.value); handleFilterChange(); }}
                  className="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                />
              </div>
            </div>
          </div>
          {hasActiveFilters && (
            <button
              onClick={clearFilters}
              className="text-sm text-red-600 hover:text-red-800 flex items-center gap-1"
            >
              <X size={14} /> Hapus Filter
            </button>
          )}
        </div>
      )}

      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        {loading ? (
          <div className="p-6 space-y-4">
            {[1, 2, 3, 4].map((i) => <div key={i} className="h-10 bg-gray-200 animate-pulse rounded" />)}
          </div>
        ) : orders.length === 0 ? (
          <div className="text-center py-12 text-gray-500">
            <ShoppingCart size={48} className="mx-auto mb-3 text-gray-300" />
            <p>Tidak ada data</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 sticky top-0">
                <tr>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">No. Pesanan</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">Kasir</th>
                  <th className="text-right py-3 px-4 font-medium text-gray-500">Total</th>
                  <th className="text-center py-3 px-4 font-medium text-gray-500">Status</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">Tanggal</th>
                  <th className="text-center py-3 px-4 font-medium text-gray-500">Aksi</th>
                </tr>
              </thead>
              <tbody>
                {orders.map((order, i) => (
                  <tr key={order.id} className={i % 2 === 0 ? 'bg-white' : 'bg-gray-50'}>
                    <td className="py-3 px-4 font-medium">{order.orderNumber}</td>
                    <td className="py-3 px-4 text-gray-600">{order.user?.name || '-'}</td>
                    <td className="py-3 px-4 text-right">Rp {order.total?.toLocaleString('id-ID')}</td>
                    <td className="py-3 px-4 text-center">
                      <span className="bg-green-100 text-green-800 px-2 py-0.5 rounded-full text-xs capitalize">
                        {order.status}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-gray-600">
                      {new Date(order.createdAt).toLocaleDateString('id-ID')}
                    </td>
                    <td className="py-3 px-4 text-center">
                      <button
                        onClick={() => viewDetail(order)}
                        className="text-blue-600 hover:text-blue-800 text-xs font-medium"
                      >
                        Detail
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {totalPages > 1 && (
          <div className="flex items-center justify-end gap-2 p-4 border-t">
            <button
              disabled={page <= 1}
              onClick={() => setPage(page - 1)}
              className="px-3 py-1 border rounded text-sm disabled:opacity-50"
            >
              Sebelumnya
            </button>
            <span className="text-sm text-gray-600">
              {page} / {totalPages}
            </span>
            <button
              disabled={page >= totalPages}
              onClick={() => setPage(page + 1)}
              className="px-3 py-1 border rounded text-sm disabled:opacity-50"
            >
              Selanjutnya
            </button>
          </div>
        )}
      </div>

      {selectedOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold">Detail Pesanan</h2>
              <button onClick={() => setSelectedOrder(null)} className="text-gray-500 hover:text-gray-700">&times;</button>
            </div>

            <div className="grid grid-cols-2 gap-4 mb-4 text-sm">
              <div>
                <p className="text-gray-500">No. Pesanan</p>
                <p className="font-medium">{selectedOrder.orderNumber}</p>
              </div>
              <div>
                <p className="text-gray-500">Status</p>
                <span className="bg-green-100 text-green-800 px-2 py-0.5 rounded-full text-xs capitalize">
                  {selectedOrder.status}
                </span>
              </div>
              <div>
                <p className="text-gray-500">Kasir</p>
                <p className="font-medium">{selectedOrder.user?.name || '-'}</p>
              </div>
              <div>
                <p className="text-gray-500">Tanggal</p>
                <p className="font-medium">
                  {new Date(selectedOrder.createdAt).toLocaleDateString('id-ID')}
                </p>
              </div>
              {selectedOrder.customer && (
                <>
                  <div>
                    <p className="text-gray-500">Pelanggan</p>
                    <p className="font-medium">{selectedOrder.customer.name}</p>
                  </div>
                  <div>
                    <p className="text-gray-500">Telepon</p>
                    <p className="font-medium">{selectedOrder.customer.phone}</p>
                  </div>
                </>
              )}
            </div>

            {selectedOrder.items && selectedOrder.items.length > 0 && (
              <div className="mb-4">
                <h3 className="text-sm font-semibold text-gray-700 mb-2">Item</h3>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b">
                        <th className="text-left py-2 font-medium text-gray-500">Produk</th>
                        <th className="text-center py-2 font-medium text-gray-500">Qty</th>
                        <th className="text-right py-2 font-medium text-gray-500">Harga</th>
                        <th className="text-right py-2 font-medium text-gray-500">Subtotal</th>
                      </tr>
                    </thead>
                    <tbody>
                      {selectedOrder.items.map((item, i) => (
                        <tr key={item.id} className={i % 2 === 0 ? '' : 'bg-gray-50'}>
                          <td className="py-2">{item.productName || '-'}</td>
                          <td className="py-2 text-center">{item.qty}</td>
                          <td className="py-2 text-right">Rp {item.price?.toLocaleString('id-ID')}</td>
                          <td className="py-2 text-right">Rp {item.subtotal?.toLocaleString('id-ID')}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {selectedOrder.payments && selectedOrder.payments.length > 0 && (
              <div className="mb-4">
                <h3 className="text-sm font-semibold text-gray-700 mb-2">Pembayaran</h3>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b">
                        <th className="text-left py-2 font-medium text-gray-500">Metode</th>
                        <th className="text-right py-2 font-medium text-gray-500">Jumlah</th>
                      </tr>
                    </thead>
                    <tbody>
                      {selectedOrder.payments.map((p, i) => (
                        <tr key={p.id} className={i % 2 === 0 ? '' : 'bg-gray-50'}>
                          <td className="py-2 capitalize">{p.method}</td>
                          <td className="py-2 text-right">Rp {p.amount?.toLocaleString('id-ID')}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            <div className="border-t pt-4 text-sm space-y-1">
              {selectedOrder.discount ? (
                <div className="flex justify-between">
                  <span className="text-gray-500">Diskon</span>
                  <span>Rp {selectedOrder.discount.toLocaleString('id-ID')}</span>
                </div>
              ) : null}
              {selectedOrder.tax ? (
                <div className="flex justify-between">
                  <span className="text-gray-500">Pajak</span>
                  <span>Rp {selectedOrder.tax.toLocaleString('id-ID')}</span>
                </div>
              ) : null}
              <div className="flex justify-between font-semibold text-base">
                <span>Total</span>
                <span>Rp {selectedOrder.total?.toLocaleString('id-ID')}</span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

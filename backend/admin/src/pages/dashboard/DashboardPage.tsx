import { useState, useEffect } from 'react'
import { Users, Package, ShoppingCart, Contact } from 'lucide-react'
import api from '../../api/client'

interface Order {
  id: string
  orderNumber: string
  user: { name: string }
  total: number
  status: string
  createdAt: string
}

export default function DashboardPage() {
  const [userCount, setUserCount] = useState(0)
  const [productCount, setProductCount] = useState(0)
  const [orderCount, setOrderCount] = useState(0)
  const [customerCount, setCustomerCount] = useState(0)
  const [recentOrders, setRecentOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [users, products, orders, customers, recent] = await Promise.all([
          api.get('/users'),
          api.get('/products'),
          api.get('/orders'),
          api.get('/customers'),
          api.get('/orders?limit=5'),
        ])
        setUserCount(users.data.length || users.data.meta?.total || 0)
        setProductCount(products.data.length || products.data.meta?.total || 0)
        setOrderCount(orders.data.length || orders.data.meta?.total || 0)
        setCustomerCount(customers.data.length || customers.data.meta?.total || 0)
        setRecentOrders(Array.isArray(recent.data) ? recent.data : recent.data.data || [])
      } catch (err) {
        console.error('Dashboard fetch error:', err)
      } finally {
        setLoading(false)
      }
    }
    fetchData()
  }, [])

  const cards = [
    { label: 'Total Pengguna', count: userCount, icon: Users, color: 'bg-blue-500' },
    { label: 'Total Produk', count: productCount, icon: Package, color: 'bg-green-500' },
    { label: 'Total Pesanan', count: orderCount, icon: ShoppingCart, color: 'bg-orange-500' },
    { label: 'Total Pelanggan', count: customerCount, icon: Contact, color: 'bg-purple-500' },
  ]

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Dashboard</h1>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {cards.map((card) => (
          <div key={card.label} className="bg-white rounded-lg shadow-sm p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">{card.label}</p>
                {loading ? (
                  <div className="h-8 w-16 bg-gray-200 animate-pulse rounded mt-1" />
                ) : (
                  <p className="text-2xl font-bold text-gray-800 mt-1">{card.count}</p>
                )}
              </div>
              <div className={`${card.color} p-3 rounded-lg`}>
                <card.icon className="text-white" size={24} />
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-lg shadow-sm p-6">
        <h2 className="text-lg font-semibold text-gray-800 mb-4">Pesanan Terbaru</h2>
        {loading ? (
          <div className="space-y-3">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="h-10 bg-gray-200 animate-pulse rounded" />
            ))}
          </div>
        ) : recentOrders.length === 0 ? (
          <p className="text-gray-500 text-center py-8">Tidak ada pesanan terbaru</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="text-left py-3 px-2 font-medium text-gray-500">No. Pesanan</th>
                  <th className="text-left py-3 px-2 font-medium text-gray-500">Kasir</th>
                  <th className="text-right py-3 px-2 font-medium text-gray-500">Total</th>
                  <th className="text-center py-3 px-2 font-medium text-gray-500">Status</th>
                  <th className="text-right py-3 px-2 font-medium text-gray-500">Tanggal</th>
                </tr>
              </thead>
              <tbody>
                {recentOrders.map((order) => (
                  <tr key={order.id} className="border-b border-gray-100 hover:bg-gray-50">
                    <td className="py-3 px-2 font-medium">{order.orderNumber}</td>
                    <td className="py-3 px-2">{order.user?.name || '-'}</td>
                    <td className="py-3 px-2 text-right">
                      Rp {order.total?.toLocaleString('id-ID')}
                    </td>
                    <td className="py-3 px-2 text-center">
                      <span className="bg-green-100 text-green-800 px-2 py-0.5 rounded-full text-xs capitalize">
                        {order.status}
                      </span>
                    </td>
                    <td className="py-3 px-2 text-right text-gray-500">
                      {new Date(order.createdAt).toLocaleDateString('id-ID')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}

import { useState, useEffect } from 'react'
import { Plus, Edit, Trash2, AlertCircle, Tags } from 'lucide-react'
import api from '../../api/client'

interface Category {
  id: string
  name: string
  createdAt: string
}

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [showModal, setShowModal] = useState(false)
  const [editing, setEditing] = useState<Category | null>(null)
  const [deleting, setDeleting] = useState<Category | null>(null)
  const [saving, setSaving] = useState(false)
  const [name, setName] = useState('')

  const fetchCategories = async () => {
    setLoading(true)
    setError('')
    try {
      const res = await api.get('/categories')
      setCategories(Array.isArray(res.data) ? res.data : res.data.data || [])
    } catch (err: any) {
      setError(err.response?.data?.message || 'Gagal memuat data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { fetchCategories() }, [])

  const openCreate = () => { setEditing(null); setName(''); setShowModal(true) }
  const openEdit = (cat: Category) => { setEditing(cat); setName(cat.name); setShowModal(true) }

  const handleSave = async () => {
    setSaving(true)
    try {
      if (editing) {
        await api.put(`/categories/${editing.id}`, { name })
      } else {
        await api.post('/categories', { name })
      }
      setShowModal(false)
      fetchCategories()
    } catch (err: any) {
      alert(err.response?.data?.message || 'Gagal menyimpan')
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async () => {
    if (!deleting) return
    try {
      await api.delete(`/categories/${deleting.id}`)
      setDeleting(null)
      fetchCategories()
    } catch (err: any) {
      alert(err.response?.data?.message || 'Gagal menghapus')
    }
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-center gap-3">
        <AlertCircle className="text-red-500" size={20} />
        <span className="text-red-700">{error}</span>
        <button onClick={fetchCategories} className="ml-auto bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm">Coba Lagi</button>
      </div>
    )
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Kategori</h1>
        <button onClick={openCreate} className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center gap-2 text-sm">
          <Plus size={16} /> Tambah Kategori
        </button>
      </div>

      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        {loading ? (
          <div className="p-6 space-y-4">
            {[1, 2, 3].map((i) => <div key={i} className="h-10 bg-gray-200 animate-pulse rounded" />)}
          </div>
        ) : categories.length === 0 ? (
          <div className="text-center py-12 text-gray-500">
            <Tags size={48} className="mx-auto mb-3 text-gray-300" />
            <p>Tidak ada data</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 sticky top-0">
                <tr>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">Nama</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">Tanggal Dibuat</th>
                  <th className="text-center py-3 px-4 font-medium text-gray-500">Aksi</th>
                </tr>
              </thead>
              <tbody>
                {categories.map((cat, i) => (
                  <tr key={cat.id} className={i % 2 === 0 ? 'bg-white' : 'bg-gray-50'}>
                    <td className="py-3 px-4 font-medium">{cat.name}</td>
                    <td className="py-3 px-4 text-gray-600">
                      {new Date(cat.createdAt).toLocaleDateString('id-ID')}
                    </td>
                    <td className="py-3 px-4 text-center">
                      <div className="flex items-center justify-center gap-2">
                        <button onClick={() => openEdit(cat)} className="text-blue-600 hover:text-blue-800"><Edit size={16} /></button>
                        <button onClick={() => setDeleting(cat)} className="text-red-600 hover:text-red-800"><Trash2 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <h2 className="text-lg font-semibold mb-4">{editing ? 'Edit Kategori' : 'Tambah Kategori'}</h2>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Nama</label>
              <input value={name} onChange={(e) => setName(e.target.value)} className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none" />
            </div>
            <div className="flex justify-end gap-3 mt-6">
              <button onClick={() => setShowModal(false)} className="px-4 py-2 border rounded-lg text-gray-600 hover:bg-gray-50">Batal</button>
              <button onClick={handleSave} disabled={saving} className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg disabled:opacity-50">
                {saving ? 'Menyimpan...' : 'Simpan'}
              </button>
            </div>
          </div>
        </div>
      )}

      {deleting && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-sm p-6">
            <h2 className="text-lg font-semibold mb-2">Konfirmasi Hapus</h2>
            <p className="text-gray-600">Yakin ingin menghapus kategori <strong>{deleting.name}</strong>?</p>
            <div className="flex justify-end gap-3 mt-6">
              <button onClick={() => setDeleting(null)} className="px-4 py-2 border rounded-lg text-gray-600 hover:bg-gray-50">Batal</button>
              <button onClick={handleDelete} className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg">Hapus</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

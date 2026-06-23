const axios = require('axios')
const readline = require('readline')

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
})

function ask(query) {
  return new Promise((resolve) => rl.question(query, resolve))
}

async function main() {
  let apiUrl = await ask(`API URL (default http://localhost:3000): `)
  if (!apiUrl) apiUrl = 'http://localhost:3000'
  apiUrl = apiUrl.replace(/\/+$/, '')

  console.log(`\nMenggunakan API: ${apiUrl}\n`)

  // Check if admin already exists
  try {
    const loginRes = await axios.post(`${apiUrl}/api/auth/login`, {
      username: 'admin',
      password: 'admin123',
    })
    console.log('Admin user already exists.')
    console.log('Token:', loginRes.data.accessToken)
    console.log('User:', JSON.stringify(loginRes.data.user, null, 2))
    rl.close()
    return
  } catch (err) {
    if (err.response && err.response.status !== 401 && err.response.status !== 404) {
      console.log('Login attempt failed with unexpected status:', err.response.status)
    } else {
      console.log('Admin user not found, creating...')
    }
  }

  // Try to register admin
  try {
    const registerRes = await axios.post(`${apiUrl}/api/auth/register`, {
      name: 'Admin',
      username: 'admin',
      password: 'admin123',
      role: 'admin',
    })
    console.log('\nAdmin user created successfully!')
    console.log('Response:', JSON.stringify(registerRes.data, null, 2))
  } catch (err) {
    if (err.response) {
      console.error('\nFailed to create admin user.')
      console.error('Status:', err.response.status)
      console.error('Message:', JSON.stringify(err.response.data, null, 2))

      // Fallback: try POST /api/users directly
      console.log('\nTrying fallback: POST /api/users ...')
      try {
        const userRes = await axios.post(`${apiUrl}/api/users`, {
          name: 'Admin',
          username: 'admin',
          password: 'admin123',
          role: 'admin',
          isActive: true,
        })
        console.log('Admin user created via /api/users:', JSON.stringify(userRes.data, null, 2))
      } catch (fallbackErr) {
        if (fallbackErr.response) {
          console.error('Fallback also failed.')
          console.error('Status:', fallbackErr.response.status)
          console.error('Message:', JSON.stringify(fallbackErr.response.data, null, 2))
        } else {
          console.error('Fallback error:', fallbackErr.message)
        }
      }
    } else {
      console.error('Error connecting to API:', err.message)
    }
  }

  rl.close()
}

main()

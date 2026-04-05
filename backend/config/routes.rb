Rails.application.routes.draw do
  # Health check endpoint
  get "/up", to: proc { [200, { "Content-Type" => "application/json" }, ['{"status":"ok"}']] }

  mount_devise_token_auth_for "User",
                             at: "auth",
                             controllers: {
                               sessions: "auth/sessions",
                               registrations: "auth/registrations"
                             }

  # 5. Public API for shop products - at the very top
  get "list-products/:shop_id", to: lambda { |env|
    request = ActionDispatch::Request.new(env)
    shop_id = request.params[:shop_id]
    Rails.logger.info "=== LIST PRODUCTS API: shop_id=#{shop_id}, full_path=#{request.path} ==="
    
    products = Product.where(shop_id: shop_id).order(created_at: :desc)
    Rails.logger.info "=== Found #{products.count} products ==="
    
    json = { products: products.map { |p| { id: p.id, name: p.name.to_s, description: p.description.to_s, price: p.price.to_f, stock_quantity: p.stock_quantity.to_i } } }.to_json
    
    [200, { "Content-Type" => "application/json" }, [json]]
  }

  # 1. Public shop pages (no auth required)
  get "/shop/:username", to: lambda { |env|
    request = ActionDispatch::Request.new(env)
    username = request.params[:username]
    mode = request.params[:mode] || "customer"
    
    Rails.logger.info "=== SHOP PAGE: username=#{username}, mode=#{mode} ==="
    Rails.logger.info "=== Available: #{Shop.pluck(:username).inspect} ==="
    
    shop = Shop.find_by(username: username)
    Rails.logger.info "=== Shop lookup result: #{shop.inspect} ==="
    
    if shop.nil?
      Rails.logger.info "=== SHOP NOT FOUND ==="
      html = "<html><body><h1>Shop not found</h1><p>Username: #{username}</p></body></html>"
      return [404, { "Content-Type" => "text/html" }, [html]]
    end
    
    Rails.logger.info "=== Shop name: #{shop.name.inspect} ==="
    
    if mode == "owner"
      html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Manage #{shop.name}</title>
          <script src="https://cdn.tailwindcss.com"></script>
        </head>
        <body class="bg-gradient-to-br from-blue-50 to-indigo-100 min-h-screen p-4">
          <div class="max-w-md w-full mx-auto">
            <h1 class="text-2xl font-bold text-gray-800 mb-2">#{shop.name}</h1>
            <p class="text-gray-600 mb-6">Manage your store</p>
            
            <div class="space-y-4">
              <div class="bg-white p-4 rounded-lg shadow">
                <h2 class="font-semibold text-lg mb-2">Add New Product</h2>
                <form id="add-product-form" class="space-y-3">
                  <input type="text" id="product_name" placeholder="Product Name" class="w-full px-3 py-2 border rounded" required>
                  <input type="number" id="product_price" placeholder="Price (ETB)" class="w-full px-3 py-2 border rounded" required>
                  <textarea id="product_description" placeholder="Description" class="w-full px-3 py-2 border rounded" rows="2"></textarea>
                  <input type="number" id="product_stock" placeholder="Stock Quantity" class="w-full px-3 py-2 border rounded" value="0">
                  <button type="submit" class="w-full bg-green-600 text-white py-2 rounded hover:bg-green-700">Add Product</button>
                </form>
                <div id="product-result" class="mt-3 text-center"></div>
              </div>
            </div>
          </div>
          
          <script>
            document.getElementById('add-product-form').addEventListener('submit', async (e) => {
              e.preventDefault();
              const name = document.getElementById('product_name').value;
              const price = document.getElementById('product_price').value;
              const description = document.getElementById('product_description').value;
              const stock = document.getElementById('product_stock').value;
              
              document.getElementById('product-result').innerHTML = '<p class="text-gray-500">Adding...</p>';
              
              try {
                const response = await fetch('/api/v1/products', {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({
                    product: {
                      name: name,
                      price: price,
                      description: description,
                      stock_quantity: stock,
                      shop_id: #{shop.id}
                    }
                  })
                });
                
                if (response.ok) {
                  document.getElementById('product-result').innerHTML = '<p class="text-green-600">Added!</p>';
                  document.getElementById('add-product-form').reset();
                } else {
                  document.getElementById('product-result').innerHTML = '<p class="text-red-600">Failed</p>';
                }
              } catch(err) {
                document.getElementById('product-result').innerHTML = '<p class="text-red-600">Error</p>';
              }
            });
          </script>
        </body>
        </html>
      HTML
    else
      html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>#{shop.name}</title>
          <script src="https://cdn.tailwindcss.com"></script>
        </head>
        <body class="bg-gradient-to-br from-blue-50 to-indigo-100 min-h-screen p-4">
          <div class="max-w-md w-full mx-auto">
            <h1 class="text-2xl font-bold text-gray-800 mb-2">#{shop.name}</h1>
            <p class="text-gray-600 mb-4">#{shop.welcome_message || "Welcome!"}</p>
            <div id="products" class="space-y-3">
              <p class="text-gray-500">Loading...</p>
            </div>
          </div>
          
          <script>
            fetch('/list-products/#{shop.id}')
              .then(r => r.json())
              .then(data => {
                const container = document.getElementById('products');
                if (data.products && data.products.length > 0) {
                  container.innerHTML = data.products.map(p => `
                    <div class="bg-white p-4 rounded-lg shadow">
                      <h3 class="font-semibold text-lg">${p.name}</h3>
                      <p class="text-gray-600">${p.description || ''}</p>
                      <div class="flex justify-between mt-2">
                        <span class="text-indigo-600 font-bold">${p.price} ETB</span>
                        <span class="text-gray-500">Stock: ${p.stock_quantity}</span>
                      </div>
                    </div>
                  `).join('');
                } else {
                  container.innerHTML = '<p class="text-gray-500">No products</p>';
                }
              })
              .catch(err => {
                document.getElementById('products').innerHTML = '<p class="text-red-500">Error: ' + err.message + '</p>';
              });
          </script>
        </body>
        </html>
      HTML
    end
    
    [200, { "Content-Type" => "text/html" }, [html]]
  }

  # 3. Shop setup webapp
  get "/setup-shop", to: lambda { |env|
    request = ActionDispatch::Request.new(env)
    user_id = request.params[:user_id]
    
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Create Your Shop</title>
        <script src="https://cdn.tailwindcss.com"></script>
      </head>
      <body class="bg-gradient-to-br from-blue-50 to-indigo-100 min-h-screen p-4">
        <div class="max-w-md w-full mx-auto">
          <h1 class="text-2xl font-bold text-gray-800 mb-2">Create Your Shop</h1>
          <p class="text-gray-600 mb-6">Set up your Telegram shop</p>
          
          <form id="setup-form" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Shop Name</label>
              <input type="text" id="shop_name" class="w-full px-4 py-2 border rounded-lg" placeholder="My Shop" required>
            </div>
            
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Shop Username</label>
              <input type="text" id="shop_username" class="w-full px-4 py-2 border rounded-lg" placeholder="myshop_bot" required>
            </div>
            
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Welcome Message</label>
              <textarea id="description" rows="2" class="w-full px-4 py-2 border rounded-lg" placeholder="Welcome!"></textarea>
            </div>
            
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Bot Token</label>
              <input type="text" id="bot_token" class="w-full px-4 py-2 border rounded-lg" placeholder="123456:xxx" required>
            </div>
            
            <button type="submit" class="w-full bg-indigo-600 text-white py-3 rounded-lg">Create Shop</button>
          </form>
          
          <div id="result" class="mt-4 hidden"></div>
        </div>
        
        <script>
          document.getElementById('setup-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const shopName = document.getElementById('shop_name').value;
            const shopUsername = document.getElementById('shop_username').value;
            const description = document.getElementById('description').value;
            const botToken = document.getElementById('bot_token').value;
            const userId = #{user_id || 'null'};
            
            document.getElementById('result').classList.remove('hidden');
            document.getElementById('result').innerHTML = '<p class="text-gray-600">Creating...</p>';
            
            try {
              const response = await fetch('/api/v1/shops/setup', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  user_id: userId,
                  shop_name: shopName,
                  shop_username: shopUsername,
                  description: description,
                  bot_token: botToken
                })
              });
              
              const text = await response.text();
              if (response.ok) {
                document.getElementById('result').innerHTML = '<p class="text-green-600">Created! ' + shopUsername + '</p>';
                setTimeout(() => { if (Telegram.WebApp) Telegram.WebApp.close(); }, 2000);
              } else {
                document.getElementById('result').innerHTML = '<p class="text-red-600">Error: ' + text + '</p>';
              }
            } catch(err) {
              document.getElementById('result').innerHTML = '<p class="text-red-600">Error: ' + err.message + '</p>';
            }
          });
        </script>
      </body>
      </html>
    HTML
    
    [200, { "Content-Type" => "text/html" }, [html]]
  }

  # 4. Public API for shop setup
  post "/api/v1/shops/setup", to: "public_shop_setup#create"

  # 5. API for the React Frontend
  namespace :api do
    namespace :v1 do
      get "seller", to: "sellers#show"
      resources :products
      resources :orders, only: [:index, :show, :update]
      resources :shops, only: [:show, :update]
    end
  end

  # 6. Webhooks for Telegram and Chapa Payments
  scope :webhooks do
    post 'telegram', to: 'webhooks/telegram#callback'
    post 'shop_bot', to: 'webhooks/shop_bot#callback'
    post 'chapa', to: 'webhooks/chapa#verify'
  end
end
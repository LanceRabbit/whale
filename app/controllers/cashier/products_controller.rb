class Cashier::ProductsController < Cashier::BaseController
  def add_to_cart
    @product = Product.find(params[:id])
    if @product.zh_name == "折價卷"
      @cart_item = current_cart.cart_items.build(product_id: @product.id, discount_off: -params[:coupon_price].to_i)
      discount_method = DiscountMethod.find_by(content: "優惠價")
      @cart_item.discount_method_code = discount_method.code
      @cart_item.save!
      puts @cart_item.discount_off
      render :json => {:id => @product.id, :zh_name => @product.zh_name,
                      :coupon_price => @cart_item.discount_off, :quantity => @cart_item.quantity,
                      }

    else
      @cart_item = current_cart.cart_items.build(product_id: @product.id)
      if @cart_item.product.quantity <=0
        flash[:alert] = "商品庫存數量錯誤"
      end
      discount_method = DiscountMethod.find_by(content: "無")
      @cart_item.discount_method_code = discount_method.code
      @cart_item.save!
      
      
      render :json => {:id => @product.id, :category => @product.category, :zh_name => @product.zh_name,
                      :price => @product.price, :upc => @product.upc, :quantity => @cart_item.quantity,
                      }
    end

      
  end
  
  def barcode_to_cart
    @product = Product.find_by(upc: params[:barcode])
    puts @product.upc
    if @product == nil
      render :json => @product
    elsif @product.status == "removed" # 如果是停用不要加
      @product = nil
      render :json => @product
    else
      @cart_item = current_cart.cart_items.build(product_id: @product.id)
      discount_method = DiscountMethod.find_by(content: "無")
      @cart_item.discount_method_code = discount_method.code
      @cart_item.save!
      if @cart_item.product.discount !=nil
        @bulletin = @cart_item.product.discount.bulletin
      else
        @bulletin = Bulletin.new
      end

      render :json => {:id => @product.id, :category => @product.category, :zh_name => @product.zh_name,
                      :price => @product.price, :upc => @product.upc, :quantity => @cart_item.quantity,
                      :bulletin => @bulletin.title, :discount_method_code => discount_method.code}
    end
      
  end
  
  def index
    @products = Product.all
  end
  
  def new
    
  end
  
  def removed_list
    @products = Product.all
  end
  
  def remove
    @product = Product.find(params[:id])
    @product.status = "removed"
    @product.save
    flash[:notice] = "商品停用成功"
    redirect_back(fallback_location: root_path)  # 導回上一頁
  end
  
  def listing
    @product = Product.find(params[:id])
    @product.status = "listing"
    @product.save
    flash[:notice] = "商品上架成功"
    redirect_back(fallback_location: root_path)  # 導回上一頁
  end
  
  def manage
    @products = Product.all
  end
  
  def edit
    @product = Product.find(params[:id])
  end
  
  def update
    @product = Product.find(params[:id])
    if @product.update(product2_params)
      flash[:notice] = "商品數量更新成功"
      redirect_to manage_cashier_products_path
    else
      flash.now[:alert] = @guest.errors.full_messages.to_sentence
      render :edit
    end
  end

  def import
    Product.update_by_file(params[:file])
    flash[:notice] = "成功匯入商品資訊"
    redirect_to cashier_products_path
  end
  
  private
  def product2_params
    params.require(:product).permit(:quantity)
  end
  
end

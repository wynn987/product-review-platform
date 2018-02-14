module SwaggerDocs::Product
  extend ActiveSupport::Concern

  included do
    include Swagger::Blocks

    swagger_schema :Product do
      key :type, :object
      key :required, [:id, :name, :description, :company_id]

      property :id do
        key :type, :integer
        key :format, :int64
      end

      property :name do
        key :type, :string
        key :example, "Postman Product"
      end

      property :description do
        key :type, :string
        key :example, "A postman API"
      end

      property :company_id do
        key :type, :integer
        key :format, :int64
      end
    end

    swagger_schema :ProductInput do
      allOf do
        schema do
          property :product do
            key :type, :object
            property :name do
              key :type, :string
              key :example, "[Enter the product name here. Example: Postman Product]"
            end

            property :description do
              key :type, :string
              key :example, "[Enter the product description here. Example: A postman API]"
            end
          end
        end
      end
    end
  end
end

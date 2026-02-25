import { MoreHorizontal } from "lucide-react";

const DUMMY_PRODUCTS = [
    {
        id: "1",
        sku: "GLD-RNG-001",
        name: "Diamond Gold Ring 18K",
        category: "Gold Jewellery",
        current_stock: 12,
        base_unit: "pcs",
        latest_selling_price: 1250.00,
    },
    {
        id: "2",
        sku: "GLD-NCK-002",
        name: "Classic Gold Chain",
        category: "Gold Jewellery",
        current_stock: 45,
        base_unit: "pcs",
        latest_selling_price: 850.00,
    },
    {
        id: "3",
        sku: "SLV-BRC-003",
        name: "Silver Charm Bracelet",
        category: "Silver Jewellery",
        current_stock: 8,
        base_unit: "pcs",
        latest_selling_price: 120.00,
    },
    {
        id: "4",
        sku: "DMD-EAR-004",
        name: "Diamond Stud Earrings",
        category: "Diamond Jewellery",
        current_stock: 3,
        base_unit: "pairs",
        latest_selling_price: 3500.00,
    },
    {
        id: "5",
        sku: "CST-WCH-005",
        name: "Custom Platinum Watch",
        category: "Custom Order",
        current_stock: 1,
        base_unit: "pcs",
        latest_selling_price: 8900.00,
    }
];

export function ProductStockTable() {
    return (
        <div className="bg-white/50 rounded-3xl p-6 shadow-sm border border-gray-100 flex flex-col gap-4 h-full">
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                    <h2 className="font-bold text-app-text px-4">Stok Produk</h2>
                </div>
                <button className="text-app-muted hover:text-app-text transition-colors">
                    <MoreHorizontal size={20} />
                </button>
            </div>

            <div className="overflow-x-auto">
                <table className="w-full text-sm text-left text-app-text">
                    <thead className="text-xs text-app-muted uppercase bg-gray-50/50 rounded-lg">
                        <tr>
                            <th scope="col" className="px-4 py-3 rounded-l-lg">Product Name</th>
                            <th scope="col" className="px-4 py-3">Stock</th>
                            <th scope="col" className="px-4 py-3 rounded-r-lg">Price</th>
                        </tr>
                    </thead>
                    <tbody>
                        {DUMMY_PRODUCTS.map((product) => (
                            <tr key={product.id} className="border-b border-gray-50 last:border-0 hover:bg-gray-50/30 transition-colors">
                                <td className="px-4 py-3">
                                    <div className="font-medium">{product.name}</div>
                                    <div className="text-xs text-app-muted">{product.sku}</div>
                                </td>
                                <td className="px-4 py-3">
                                    <span className={`font-medium ${product.current_stock < 10 ? 'text-red-500' : 'text-app-text'}`}>
                                        {product.current_stock}
                                    </span>
                                    <span className="text-xs text-app-muted ml-1">{product.base_unit}</span>
                                </td>
                                <td className="px-4 py-3 font-medium">
                                    ${product.latest_selling_price.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
            <div className="mt-auto pt-4 border-t border-gray-100">
                <button className="w-full py-2 text-sm font-medium text-app-text border border-gray-200 rounded-xl hover:bg-gray-50 transition-colors">
                    View All Products
                </button>
            </div>
        </div>
    );
}

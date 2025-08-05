-- Análise Completa das Vendas - Passo a Passo

USE ContosoRetailDW
GO

--Parte 01: Quantidade total de registros na tabela de vendas
SELECT COUNT(*) AS Total_Registros
FROM FactSales;

-- Parte 02: Média de vendas por transação nos Estados Unidos
-- Uni a tabela de vendas com localização e filtrei pelo país "United States"
-- JOIN feito com Dimstore e DimGeography na Factsales
SELECT 
     G.RegionCountryName
    ,AVG(F.SalesAmount) AS Media_Vendas_USA
FROM FactSales AS F
JOIN DimStore AS S ON F.StoreKey = S.StoreKey
JOIN DimGeography AS G ON S.GeographyKey = G.GeographyKey
WHERE G.RegionCountryName = 'United States'
GROUP BY G.RegionCountryName

-- Parte 03: Top 10 produtos mais vendidos por categoria
-- Usei uma CTE para facilitar a leitura e ranqueamento por quantidade vendida
-- Fiz múltiplos joins com outras 3 tabelas com dados importantes
;WITH ProdutosMaisVendidos AS (
    SELECT 
         C.ProductCategoryName
        ,P.ProductName
        ,SUM(F.SalesQuantity) AS QuantidadeVendida
        ,DENSE_RANK() OVER (PARTITION BY C.ProductCategoryName ORDER BY SUM(F.SalesQuantity) DESC) AS Posicao
    FROM FactSales AS F
    JOIN DimProduct AS P ON F.ProductKey = P.ProductKey
    JOIN DimProductSubcategory AS S ON P.ProductSubcategoryKey = S.ProductSubcategoryKey
    JOIN DimProductCategory AS C ON S.ProductCategoryKey = C.ProductCategoryKey
    GROUP BY C.ProductCategoryName, P.ProductName
)

SELECT *
FROM ProdutosMaisVendidos
WHERE Posicao BETWEEN 1 AND 10;

-- Parte 04: Tendência de vendas por mês
-- Agrupei por ano e mês para identificar padrões sazonais
SELECT 
     D.CalendarYear
    ,D.CalendarMonthLabel AS Mes
    ,SUM(F.SalesAmount) AS TotalVendas
FROM FactSales AS F
JOIN DimDate AS D ON F.DateKey = D.DateKey
GROUP BY D.CalendarYear, D.CalendarMonth, D.CalendarMonthLabel
ORDER BY D.CalendarYear, D.CalendarMonth;

-- Parte 05: Receita dos produtos mais vendidos
-- Reaproveitei a lógica de ranking da Parte 03 para calcular a receita gerada apenas pelos Top 10 produtos mais vendidos de cada categoria
-- Assim consegui entender quais subcategorias mais contribuem financeiramente entre os produtos de maior saída

;WITH ProdutosMaisVendidos AS (
    SELECT 
         C.ProductCategoryName
        ,S.ProductSubcategoryName
        ,P.ProductName
        ,SUM(F.SalesQuantity) AS QuantidadeVendida
        ,SUM(F.SalesAmount) AS Receita
        ,DENSE_RANK() OVER (PARTITION BY C.ProductCategoryName ORDER BY SUM(F.SalesQuantity) DESC) AS Posicao
    FROM FactSales AS F
    JOIN DimProduct AS P ON F.ProductKey = P.ProductKey
    JOIN DimProductSubcategory AS S ON P.ProductSubcategoryKey = S.ProductSubcategoryKey
    JOIN DimProductCategory AS C ON S.ProductCategoryKey = C.ProductCategoryKey
    GROUP BY C.ProductCategoryName, S.ProductSubcategoryName, P.ProductName
)
-- Receita apenas dos produtos mais vendidos por categoria
SELECT 
     ProductCategoryName
    ,ProductSubcategoryName
    ,SUM(Receita) AS Receita_Top_10
FROM ProdutosMaisVendidos
WHERE Posicao BETWEEN 1 AND 10
GROUP BY ProductCategoryName, ProductSubcategoryName
ORDER BY Receita_Top_10 DESC;


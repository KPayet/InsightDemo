require(rgdal)
require(ggvis)
require(ggplot2)
require(choroplethr)
require(plotly)

drawMap = function(map_df, method) {
    
    if(method == "choroplethr") {
        if(names(map_df) != c("region", "value")) {
            print("Wrong format!")
            return()
        }
        
        canvas()
        state_choropleth(df = map_df, num_colors = 9)
    }
    else if(method == "plotly"){
        map_df$hover = with(map_df, region, '<br>', value)
        
        l <- list(color = toRGB("grey"), width = 1)
        
        geoInfo <- list(
                scope = 'usa',
                projection = list(type = 'albers usa'),
                showlakes = TRUE,
                lakecolor = toRGB('white')
        )
        #canvas()
        plot_ly(map_df, z = value, text = hover, locations = code, type = 'choropleth',
                locationmode = 'USA-states', color = value, colors = 'Purples',
                marker = list(line = l), colorbar = list(title = "Sentiment score")) %>%
            layout(title = 'Insert title', geo = geoInfo)
    }
    
}

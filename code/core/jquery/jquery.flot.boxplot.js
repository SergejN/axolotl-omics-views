/*
 * Flot Plugin to draw box plots
 *
 * Created by Kevin Angstadt, June 2012
 *
 * To enable the plugin, you must set the show property
 * for boxplot in the series options to true, e.g.
 *
 *  $.plot("#placeholder", data, {series:{boxplot:{show: true}}});
 *
 *  For a boxplot, data should be an array of arrays of the dataset, e.g.
 *  [[-5],[-10],[10],[2],[1],[20],[30]].  If you want each datapoint to hold
 *  more data, put that in each array as an array of data, e.g.
 *  [[-5,["foo","bar]], [0, ["foo","bar]]].  Each one must have the same length.
 *
 *  To plot multiple boxplots on a single flot plot, pass in each
 *  dataset as a separate series.  The boxplots will stack vertically.
 *
 *  If there are two or more boxplots, the boxplos will be labelled
 *  on the vertical axis with the series's label.  If the series does
 *  not have a label, then the boxplot will be labelled 'dataX', where
 *  X is the index of the series in the data array.
 *
 *  Outliers are plotted with stars that stack vertically if there
 *  are duplicates.  There is also a primative algorithm that will
 *  center these outliers on the boxplot.
 *
 */

(function ($){
    function init(plot) { // "plugin body"
        var xmin = Number.POSITIVE_INFINITY;
        var xmax = Number.NEGATIVE_INFINITY;
        var count = 0; //use this to keep track of the series
        var ticks = [];
        
        plot.hooks.processOptions.push(checkBoxPlotEnabled);
        
        //check to see if the box plot is enabled
        function checkBoxPlotEnabled(plot, options) {
            if(options.series.boxplot.show) {
                
                //add processData hook to do calculations on data
                plot.hooks.processRawData.push(processRawData);
                plot.hooks.processDatapoints.push(processDatapoints);
                
                //turn off line; turn on points
                options.series.lines.show = false;
                options.series.points.show = true;
                
                //add draw hook
                plot.hooks.drawSeries.push(draw);
            }
        }
        
        function processRawData(plot, series, data, datapoints) {
            function quartile(p) {
                var index = p * (data.length + 1);
                if(parseInt(index) + 0.5 === index && p === 0.5) {
                    var k = parseInt(index);
                    return (data[k-1][0] + data[k][0]) / 2;
                } else {
                    return data[index.toFixed(0)-1][0];
                }
            }
            
            //make sure our data is sorted first
            data.sort(function(a,b){
                var x = parseFloat(a[0]);
                var y = parseFloat(b[0]);
                return (x > y) ? 1 : (x < y) ? -1: 0;
            });
            
            series.q1 = quartile(0.25);
            series.m = quartile(0.5);
            series.q3 = quartile(0.75);
            
            var upper_bound = series.q3 + 1.5 * (series.q3 - series.q1);
            var lower_bound = series.q1 - 1.5 * (series.q3 - series.q1);
            
            $.each(data, function(key,value){
                if(!series.lower_bound && series.lower_bound !== 0 && value[0] >= lower_bound) {
                    series.lower_bound = value[0];
                }
                if(!series.upper_bound && series.upper_bound !== 0 && value[0] > upper_bound) {
                    series.upper_bound = data[key-1][0];
                    return false;
                }
            });
            //if still no upper_bound, then it's the last item in the data
            series.upper_bound = series.upper_bound || data[data.length-1][0];
            
            //say we're using the x and y axes
            series.xaxis.used = series.yaxis.used = true;
            
            datapoints.pointsize = 2 + ($.isArray(data[0][1]) ? data[0][1].length : 0);
            
            series.count = count; //let the series remember its number
            
            $.each(data, function(key, value) {
                if(value[0] > series.upper_bound || value[0] < series.lower_bound) {
                    //stack outliers
                    var yval = count;
                    var from = 0;
                    while(from < datapoints.points.length){
                        var inArray = $.inArray(value[0],datapoints.points,from)
                        if(inArray > -1) {
                            if(datapoints.points[inArray+1] !== (count - (yval - count)) && yval > count) {
                                yval = count - (yval - count);
                            } else {
                                //then we have one already so shift the y-value
                                yval = count + Math.abs(yval - count) + 0.05;
                                
                                //if we have too many stacked, start overlaying
                                if(yval > count + .4){
                                    yval = count;
                                }
                            }
                            from = inArray + datapoints.pointsize;
                        } else {
                            break;
                        }
                    }
                    datapoints.points.push(value[0], yval);
                    if(datapoints.pointsize > 2){
                        $.each(value[1], function(i, val){
                            datapoints.points.push(val);
                        });
                    }

                }
            });
            
            //set the x-bounds
            if(plot.getOptions().xaxis.max == null){
                xmax = Math.max( data[data.length -1][0] + (data[data.length-1][0] - data[0][0]) * 0.05 , xmax);
                plot.getXAxes()[0].datamax = xmax;
            }
            if(plot.getOptions().xaxis.min == null){
                xmin = Math.min(data[0][0] - (data[data.length-1][0] - data[0][0]) * 0.05, xmin);
                plot.getXAxes()[0].datamin = xmin
            }
            
            //set the y-bounds
            if(plot.getOptions().yaxis.max == null) {
                plot.getYAxes()[0].datamax = count + .5;
            }
            if(plot.getOptions().yaxis.min == null) {
                plot.getYAxes()[0].datamin = -0.5;
            }
            
            //make points crosses rather than circles
            series.points.radius = 4;
            series.points.symbol = function (ctx, x, y, radius, shadow) {
                // pi * r^2 = (2s)^2  =>  s = r * sqrt(pi)/2
                var size = radius * Math.sqrt(Math.PI) / 2;
                ctx.moveTo(x - size, y - size);
                ctx.lineTo(x + size, y + size);
                ctx.moveTo(x - size, y + size);
                ctx.lineTo(x + size, y - size);
                ctx.moveTo(x, y - size);
                ctx.lineTo(x, y + size);
                ctx.moveTo(x - size, y);
                ctx.lineTo(x + size, y);
            };
            
            //set the axis label
            ticks.push([count, series.label || "data"+count]);
            
            count = count + 1; //update our count for the next series, if there is one.
        }
        
        function processDatapoints(plot, series, datapoints) {
            if(plot.getData().length > 1) {
                series.yaxis.options.ticks = generateTicks;
            } else {
                series.yaxis.options.ticks = [];
            }
            
        }
        
        function draw(plot, ctx, series) {
            var x = series.xaxis;
            var y = series.yaxis;
            
            var width = x.p2c(series.q3) - x.p2c(series.q1);
            var height = y.p2c(-.25) - y.p2c(.25);
            
            var seriesY = series.count;
            var yTop = y.p2c(seriesY+.25)+plot.getPlotOffset().top; //top of box with offset coordinate
            var q1c = x.p2c(series.q1)+plot.getPlotOffset().left; //q1 coordinate on ctx
            var q3c = x.p2c(series.q3)+plot.getPlotOffset().left; //q3 coordinate on ctx
            var mc = x.p2c(series.m)+plot.getPlotOffset().left; //m coordinate on ctx
            var center = y.p2c(seriesY)+plot.getPlotOffset().top; //center (vertically) of the box plot
            var lower_boundC = x.p2c(series.lower_bound)+plot.getPlotOffset().left // lower_bound coordinate on ctx
            var upper_boundC = x.p2c(series.upper_bound)+plot.getPlotOffset().left // upper_bound coordinate on ctx
            
            //draw box with correct offset
            ctx.strokeRect(q1c, yTop, width, height);
            
            //draw median line
            ctx.beginPath();
            ctx.moveTo(mc, yTop);
            ctx.lineTo(mc, yTop + height);
            ctx.closePath();
            ctx.stroke();
            
            //draw lower whisker
            ctx.beginPath();
            ctx.moveTo(q1c, center);
            ctx.lineTo(lower_boundC, center);
            ctx.closePath();
            ctx.stroke();
            
            //draw upper whisker
            ctx.beginPath();
            ctx.moveTo(q3c, center);
            ctx.lineTo(upper_boundC, center);
            ctx.closePath();
            ctx.stroke();
        }
        
        function generateTicks(axis) {
            return ticks;
        }
    } // end init (plugin body)
    
    //Define boxplot options and default values
    var options = {
        series: {
            boxplot: {
                show: false
            }
        }
    };
    
    $.plot.plugins.push({
        init: init,
        options: options,
        name: 'boxplot',
        version: '1.0'
    })
})(jQuery);
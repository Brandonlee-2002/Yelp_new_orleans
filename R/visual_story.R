# Presentation chart generated from the completed, exported ranking.
library(ggplot2)
x <- read.csv("data/analysis/top_15_restaurants.csv",stringsAsFactors=FALSE)
x$label <- paste0(sprintf("%02d",x$rank),"  ",x$business_name)
x$label <- factor(x$label,levels=rev(x$label))
p <- ggplot(x,aes(x=label,y=adjusted_mean))+
 geom_col(aes(fill=rank<=3),width=.62,show.legend=FALSE)+
 scale_fill_manual(values=c("FALSE"="#176b75","TRUE"="#ae6e35"))+
 geom_text(aes(label=sprintf("+%.3f",adjusted_mean)),hjust=-.15,size=3.4,color="#173d43")+
 coord_flip(clip="off")+
 scale_y_continuous(limits=c(0,.69),breaks=c(0,.2,.4,.6),expand=expansion(mult=c(0,0)))+
 labs(title="Fifteen restaurants that outperform reviewers' usual scores",
 subtitle="Mean reviewer-adjusted deviation · eligible reviewers have five city/category reviews",
 x=NULL,y="Adjusted deviation in star points",
 caption="Historical snapshot · each restaurant has 50+ total reviews and 20+ distinct eligible reviewers.\nAdjusted deviations are not new Yelp star ratings; sample sizes differ across restaurants.")+
 theme_minimal(base_size=12)+theme(panel.grid.major.y=element_blank(),panel.grid.minor=element_blank(),
  plot.title=element_text(face="bold",size=15,color="#173d43"),
  plot.subtitle=element_text(color="#617375",size=11),axis.text.y=element_text(size=10,color="#173d43"),
  plot.caption=element_text(hjust=0,size=9,color="#617375"),plot.margin=margin(18,30,16,14))
ggsave("figures/story_top_15.png",p,width=11,height=8,dpi=180,bg="#fafbf8")

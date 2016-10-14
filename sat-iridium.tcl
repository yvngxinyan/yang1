#
# Copyright (c) 1999 Regents of the University of California.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#       This product includes software developed by the MASH Research
#       Group at the University of California Berkeley.
# 4. Neither the name of the University nor of the Research Group may be
#    used to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# Contributed by Tom Henderson, UCB Daedalus Research Group, June 1999
#
# $Header: /cvsroot/nsnam/ns-2/tcl/ex/sat-iridium.tcl,v 1.4 2001/11/06 06:20:11 tomh Exp $
#
# Example of a broadband LEO constellation with orbital configuration 
# similar to that of Iridium.  The script sets up two terminals (one in 
# Boston, one at Berkeley) and sends a packet from Berkeley to Boston
# every second for a whole day-- the script illustrates how the latency
# due to propagation delay changes depending on the satellite configuration. 
#
# This script relies on sourcing two additional files:
# - sat-iridium-nodes.tcl
# - sat-iridium-links.tcl
# Iridium does not have crossseam ISLs-- to enable crossseam ISLs, uncomment 
# the last few lines of "sat-iridium-links.tcl"
#
# Iridium parameters [primary reference:  "Satellite-Based Global Cellular
# Communications by Bruno Pattan (1997-- McGraw-Hill)]
# Altitude = 780 km
# Orbital period = 6026.9 sec
# intersatellite separation = 360/11 deg
# interplane separation = 31.6 deg
# seam separation = 22 deg
# inclination = 86.4
# eccentricity =  0.002 (not modelled)
# minimum elevation angle at edge of coverage = 8.2 deg
# ISL cross-link pattern:  2 intraplane to nearest neighbors in plane, 
#   2 interplane except at seam where only 1 interplane exists

#模拟了一个宽带LEO星群,该星群的参数与Iridium星群的参数类似
global ns
set ns [new Simulator] 

# Global configuration parameters 全局配置参数
HandoffManager/Term set elevation_mask_ 8.2 
# 通过 OTcl 进行设置截止高度角
HandoffManager/Term set term_handoff_int_ 10
 #切换定时器间隔
HandoffManager/Sat set sat_handoff_int_ 10 
# 秒;卫星切换时间间隔通过 OTcl 设置,同样也可以是随机的
HandoffManager/Sat set latitude_threshold_ 60 
#纬度的阈值
HandoffManager/Sat set longitude_threshold_ 10 
#经度值
HandoffManager set handoff_randomization_ true 
#使切换随机发生以避免相位影响 0 表示“否”,1 表示“是”
#如果为 1,则下一个切换时间间隔将是在(0.5*term_handoff_int_, 1.5*term_handoff_int_) 区间内服从均匀分布的一个随机值。

SatRouteObject set metric_delay_ true
#度量延迟
#最短路径(shortest-path)路由算法使用链路当前的传播延时作为开销矩阵来进行计算
# Set this to false if opt(wiredRouting) == ON below 如果opt＝on 将其置为false
SatRouteObject set data_driven_computation_ true
#开启 data-driven 路由计算。在 data-driven 计算下,路由只有在有分组发送 时才计算,此外,它执行单源(single-source)最短路径算法(只对有分组发送的节点)代替所有节点对最短路径算法。
# "ns-random 0" sets seed heuristically#试探性地; other integers are deterministic其他整数是确定的
ns-random 1
Agent set ttl_ 32; 
# Should be > than max diameter in network应大于网络中的最大直径

# One plane of Iridium-like satellites一个类似铱的卫星

global opt
set opt(chan)           Channel/Sat
set opt(bw_down)        1.5Mb; 
# Downlink bandwidth (satellite to ground)下行带宽（卫星到地面）
set opt(bw_up)          1.5Mb;
 # Uplink bandwidth上行带宽
set opt(bw_isl)         25Mb
set opt(phy)            Phy/Sat
#物理层类型 Phy/Sat类仅在协议栈中上下 传递信息
set opt(mac)            Mac/Sat
#MAC 类型  Mac/Sat 类用于只有一个接收者的链路(不需要做碰撞检测)
set opt(ifq)            Queue/DropTail
set opt(qlim)           50
#接口队列的长度,以分组为单位
set opt(ll)             LL/Sat
#链路层类型
set opt(wiredRouting) 	OFF
#有线路由

set opt(alt)            780;
 # Polar satellite altitude (Iridium)极地卫星高度（铱）
set opt(inc)            86.4;
 # Orbit inclination w.r.t. equator关于赤道轨道倾角

# XXX This tracing enabling must precede link and node creation此跟踪启用必须在链接和节点创建之前
set outfile [open out.tr w]
$ns trace-all $outfile

# Create the satellite nodes创建卫星节点
# Nodes 0-99 are satellite nodes; 100 and higher are earth terminals
#节点0-99是卫星节点；100和较高的节点是地球终端

#$ns_ node-config -<config-parameter> <optional-val>
#p171 极轨道卫星有一个纯圆平面轨道,这个平面在坐标系统中是固定的。地球在这个轨道平面下面自转。 因此,一个极轨道卫星在地球表面上的覆盖区轨迹同时包含东西方向的和南北方向。严格地讲,极位置对象(polar position object)可以用来模拟一个固定平面内任何圆形轨道的运动。我们在此使用“polar”这一术语是因为后面将 使用这样的卫星来模拟极轨道卫星星群。
$ns node-config -satNodeType polar \
		-llType $opt(ll) \
		-ifqType $opt(ifq) \
		-ifqLen $opt(qlim) \
		-macType $opt(mac) \
		-phyType $opt(phy) \
		-channelType $opt(chan) \
		-downlinkBW $opt(bw_down) \
		-wiredRouting $opt(wiredRouting) 

set alt $opt(alt)
#极轨道卫星的海拔
set inc $opt(inc)
#轨道倾斜度

source sat-iridium-nodes.tcl

# 配置链路configure the ISLs
source sat-iridium-links.tcl

# Set up terrestrial nodes建立地面节点
$ns node-config -satNodeType terminal
set n100 [$ns node]
$n100 set-position 37.9 -122.3; # Berkeley
set n101 [$ns node]
$n101 set-position 42.3 -71.1; # Boston 

# Add GSL links GSL链接添加
# It doesn't matter what the sat node is (handoff algorithm will reset it)
#sat节点是什么不重要（切换算法将重置）
$n100 add-gsl polar $opt(ll) $opt(ifq) $opt(qlim) $opt(mac) $opt(bw_up) \
  $opt(phy) [$n0 set downlink_] [$n0 set uplink_]
$n101 add-gsl polar $opt(ll) $opt(ifq) $opt(qlim) $opt(mac) $opt(bw_up) \
  $opt(phy) [$n0 set downlink_] [$n0 set uplink_]

# Trace all queues跟踪所有的队列
$ns trace-all-satlinks $outfile

# 附加代理Attach agents
set udp0 [new Agent/UDP]
 # 创建UDP agent
$ns attach-agent $n100 $udp0 
# 在节点n100上
set cbr0 [new Application/Traffic/CBR] 
# CBR流量产生器agent
$cbr0 attach-agent $udp0 
#将cbr与udp关联起来
$cbr0 set interval_ 60.01

set null0 [new Agent/Null]
#空代理 通常是用作丢弃接收到的packet的接收器,或者用作那些在模拟中不被统计和记录的packet的目的地。
$ns attach-agent $n101 $null0

$ns connect $udp0 $null0
$ns at 1.0 "$cbr0 start"
#CBR 流量产生器在 1.0s 时启动

# We're using a centralized routing genie-- create and start it here
#我们使用一个集中的路由－在这里创建和启动它
set satrouteobject_ [new SatRouteObject]
$satrouteobject_ compute_routes

$ns at 86400.0 "finish" ; 
# one earth rotation 地球自转一圈的时间

proc finish {} {
	global ns outfile 
	$ns flush-trace
	close $outfile

	exit 0
}

$ns run
#最后,开始模拟


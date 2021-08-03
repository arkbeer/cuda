#include<iostream>
#include<iomanip>
#include<array>
template<typename T>
class interval{
public:
    T x,y;
    __device__ interval<T> sqrt(){
        return interval<T>{__dsqrt_rd(x),__dsqrt_ru(y)};
    }
};

template<typename T>
__device__ interval<T> operator+(const interval<T>& left, const interval<T>& right){
    return interval<T>{0,0};
}
template<>
__device__ interval<double> operator+(const interval<double>& left, const interval<double>& right){
    return interval<double>{__dadd_rd(left.x,right.x),__dadd_ru(left.y,right.y)};
}

template<typename T>
__device__ interval<T> operator-(const interval<T>& left, const interval<T>& right){
    return interval<T>{0,0};
}
template<>
__device__ interval<double> operator-(const interval<double>& left, const interval<double>& right){
    return interval<double>{__dsub_rd(left.x,right.x),__dsub_ru(left.y,right.y)};
}

template<typename T>
__device__ interval<T> operator*(const interval<T>& left, const interval<T>& right){
    return interval<T>{0,0};
}
template<>
__device__ interval<double> operator*(const interval<double>& left, const interval<double>& right){
    if(right.y<0){
        if(left.y<0){
            return interval<double>{__dmul_rd(left.y,right.y),__dmul_ru(left.x,right.x)};
        }else if(left.x>0){
            return interval<double>{__dmul_rd(left.y,right.x),__dmul_ru(left.x,right.y)};
        }else return interval<double>{__dmul_rd(left.y,right.x),__dmul_ru(left.x,right.x)};
    }else if(right.x>0){
        if(left.y<0){
            return interval<double>{__dmul_rd(left.x,right.y),__dmul_ru(left.y,right.x)};
        }else if(left.x>0){
            return interval<double>{__dmul_rd(left.x,right.x),__dmul_ru(left.y,right.y)};
        }else return interval<double>{__dmul_rd(left.x,right.y),__dmul_ru(left.y,right.y)};
    }else{
        if(left.y<0){
            return interval<double>{__dmul_rd(left.x,right.y),__dmul_ru(left.x,right.x)};
        }else if(left.x>0){
            return interval<double>{__dmul_rd(left.y,right.x),__dmul_ru(left.y,right.y)};
        }else {
            double x1=__dmul_rd(left.x,right.y);
            double x2=__dmul_rd(left.y,right.x);
            double y1=__dmul_ru(left.x,right.x);
            double y2=__dmul_ru(left.y,right.y);
            return interval<double>{x1<x2?x1:x2,y1>y2?y1:y2};
        }
    }
}

template<typename T>
__device__ interval<T> operator/(const interval<T>& left, const interval<T>& right){
    return interval<T>{0,0};
}
template<>
__device__ interval<double> operator/(const interval<double>& left, const interval<double>& right){
    if(right.y<0){
        if(left.y<0){
            return interval<double>{__ddiv_rd(left.y,right.x),__ddiv_ru(left.x,right.y)};
        }else if(left.x>0){
            return interval<double>{__ddiv_rd(left.y,right.y),__ddiv_ru(left.x,right.x)};
        }else return interval<double>{__ddiv_rd(left.y,right.y),__ddiv_ru(left.x,right.y)};
    }else{
        if(left.y<0){
            return interval<double>{__ddiv_rd(left.x,right.x),__ddiv_ru(left.y,right.y)};
        }else if(left.x>0){
            return interval<double>{__ddiv_rd(left.x,right.y),__ddiv_ru(left.y,right.x)};
        }else return interval<double>{__ddiv_rd(left.x,right.x),__ddiv_ru(left.y,right.x)};
    }
}

__global__ void kernel(interval<double> a,interval<double> b, interval<double> *c) {
    c[0]=a+b;
    c[1]=a-b;
    c[2]=a*b;
    c[3]=a/b;
    c[4]=a.sqrt();
    }
    
int main() {
    std::array<interval<double>,5> c;
    interval<double> *dev_c;
    cudaMalloc(reinterpret_cast<void**>(&dev_c),sizeof(interval<double>)*5);
    
    kernel<<<1,1>>>(interval<double>{0.333333333333333,1},interval<double>{0.999999999999999,3},dev_c);
    cudaDeviceSynchronize();
    cudaMemcpy(c.data(),dev_c,sizeof(interval<double>)*5,cudaMemcpyDeviceToHost);
    cudaFree(dev_c);
    
    for(const auto& v:c){
        std::cout<<"["<<std::fixed<<std::setprecision(15)<<v.x<<", "<<v.y<<"]"<<std::endl;
    }
    return 0;
}